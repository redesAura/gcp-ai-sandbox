# 0001 - Región principal us-central1

Contexto:
El sandbox necesita GPU (L4, A100, H100), TPU y los modelos Gemini de Vertex AI. No requiere alta disponibilidad multirregión: se respaldan datasets y modelos, y el cómputo se recrea con Terraform.

Decisión:
- us-central1 es la región principal, por tener la mayor oferta de GPU, TPU y modelos Gemini.
- us-east4 es la región alterna, solo para conseguir capacidad de GPU cuando us-central1 no la tenga.
- Ninguna otra región está permitida: las variables `region` de cada etapa solo aceptan esas dos y 1-org lo impone con la política gcp.resourceLocations.

Consecuencias:
- Los recursos regionales de la base (bucket de estado, logs, secretos) viven en us-central1.
- Una llave CMEK debe estar en la misma región que el recurso que cifra, así que 2-security crea un key ring en cada una de las dos regiones.
- La cuota de GPU H100 y de TPU depende de la aprobación de Google y se solicita en la semana 1; el plan alterno es L4 y A100, o us-east4.
