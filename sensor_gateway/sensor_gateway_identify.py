
import os
import json
import time
import paho.mqtt.client as mqtt
import requests

MQTT_BROKER = os.getenv("MQTT_BROKER", "localhost")
MQTT_PORT = int(os.getenv("MQTT_PORT", 1883))
MQTT_TOPIC = "sensors/data"

API_URL = os.getenv("API_URL", "http://localhost:3000/api/sensors")
API_TOKEN = os.getenv("API_TOKEN", "abc123supersecreto")

HEADERS = {{
    "Authorization": f"Bearer {{API_TOKEN}}",
    "Content-Type": "application/json"
}}

def identify_or_create_sensor(device_id):
    try:
        response = requests.get(
            f"{{API_URL}}/identify?device_id={{device_id}}",
            headers=HEADERS,
            timeout=5
        )
        if response.status_code == 200:
            data = response.json()
            print(f"🆔 Sensor encontrado ou criado: ID={{data['id']}}, name={{data['name']}}")
            return data["id"]
        else:
            print("❌ Erro ao identificar/criar sensor:", response.status_code)
            return None
    except Exception as e:
        print("❌ Exceção ao identificar sensor:", e)
        return None

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("✅ Ligado ao broker MQTT")
        client.subscribe(MQTT_TOPIC)
    else:
        print("❌ Erro ao ligar ao MQTT:", rc)

def on_message(client, userdata, msg):
    try:
        payload = json.loads(msg.payload.decode())
        sensor_id = payload.get("sensor_id")
        print(f"📦 Recebido do sensor {{sensor_id}}: {{payload}}")

        if not sensor_id:
            print("⚠️ Payload sem sensor_id")
            return

        response = requests.post(
            f"{{API_URL}}/{{sensor_id}}/readings",
            json=payload,
            headers=HEADERS,
            timeout=5
        )

        print(f"🔁 Enviado para Rails (Sensor #{{sensor_id}}): {{response.status_code}}")

    except Exception as e:
        print("❌ Erro ao processar mensagem:", e)

def main():
    print("🚀 Sensor Gateway a iniciar...")

    # Identificar ou criar o sensor antes de escutar mensagens
    device_id = os.getenv("DEVICE_ID", "sensor_pico_01")
    sensor_id = identify_or_create_sensor(device_id)

    if not sensor_id:
        print("⚠️ Não foi possível continuar sem sensor ID.")
        return

    # Guardar o sensor_id numa variável global ou partilhar no payload MQTT
    os.environ["CURRENT_SENSOR_ID"] = str(sensor_id)

    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_message = on_message

    client.connect(MQTT_BROKER, MQTT_PORT, 60)
    client.loop_forever()

if __name__ == "__main__":
    main()
