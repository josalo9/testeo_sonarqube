// Package p contiene una Cloud Function que orquesta la ingesta de datos.
package p

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"sync"

	"cloud.google.com/go/firestore"
	"cloud.google.com/go/pubsub"
	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
	"github.com/cloudevents/sdk-go/v2/event"
)

var (
	projectID      string
	ingestionTopic string
	fsClient       *firestore.Client
	psClient       *pubsub.Client
	initOnce       sync.Once
	initErr        error
)

// init se encarga de la inicialización de clientes y variables de entorno.
func init() {
	functions.CloudEvent("IngestionOrchestrator", IngestionOrchestrator)

	initOnce.Do(func() {
		ctx := context.Background()
		projectID = os.Getenv("GCP_PROJECT")
		if projectID == "" {
			initErr = fmt.Errorf("GCP_PROJECT environment variable must be set")
			return
		}

		ingestionTopic = os.Getenv("INGESTION_TOPIC_ID")
		if ingestionTopic == "" {
			initErr = fmt.Errorf("INGESTION_TOPIC_ID environment variable must be set")
			return
		}

		fsClient, initErr = firestore.NewClient(ctx, projectID)
		if initErr != nil {
			initErr = fmt.Errorf("firestore.NewClient: %v", initErr)
			return
		}

		psClient, initErr = pubsub.NewClient(ctx, projectID)
		if initErr != nil {
			initErr = fmt.Errorf("pubsub.NewClient: %v", initErr)
			return
		}
	})
}

// IngestionOrchestrator es una Cloud Function que lee proveedores activos de Firestore
// y publica un mensaje en Pub/Sub para cada uno.
func IngestionOrchestrator(ctx context.Context, e event.Event) error {
	if initErr != nil {
		log.Printf("Error en inicialización: %v", initErr)
		return initErr
	}

	providers, err := getActiveProviders(ctx)
	if err != nil {
		log.Printf("Error al obtener proveedores activos: %v", err)
		return err
	}

	if len(providers) == 0 {
		log.Println("No se encontraron proveedores activos para procesar.")
		return nil
	}

	var wg sync.WaitGroup
	successCount := 0
	errorCount := 0

	topic := psClient.Topic(ingestionTopic)

	for _, provider := range providers {
		wg.Add(1)
		go func(p map[string]interface{}) {
			defer wg.Done()
			providerID, ok := p["id"].(string)
			if !ok {
				log.Printf("Error: el ID del proveedor no es un string: %v", p)
				errorCount++
				return
			}

			msgData, err := json.Marshal(map[string]string{"provider_id": providerID})
			if err != nil {
				log.Printf("Error al serializar mensaje para proveedor %s: %v", providerID, err)
				errorCount++
				return
			}

			res := topic.Publish(ctx, &pubsub.Message{Data: msgData})
			if _, err := res.Get(ctx); err != nil {
				log.Printf("Error al publicar mensaje para proveedor %s: %v", providerID, err)
				errorCount++
				return
			}
			successCount++
		}(provider)
	}

	wg.Wait()

	log.Printf("Resumen de ejecución: %d proveedores procesados exitosamente, %d fallaron.", successCount, errorCount)
	return nil
}

// getActiveProviders consulta Firestore para obtener los proveedores activos.
func getActiveProviders(ctx context.Context) ([]map[string]interface{}, error) {
	var providers []map[string]interface{}
	iter := fsClient.Collection("providers").Where("active", "==", true).Documents(ctx)
	docs, err := iter.GetAll()
	if err != nil {
		return nil, fmt.Errorf("iter.GetAll: %v", err)
	}

	for _, doc := range docs {
		providerData := doc.Data()
		providerData["id"] = doc.Ref.ID
		providers = append(providers, providerData)
	}
	return providers, nil
}
