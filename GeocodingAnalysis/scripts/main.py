import json
import os
import time
import warnings
import csv
from collections import defaultdict

import openpyxl
import requests
from dotenv import load_dotenv, set_key

def read_excel(filename):
    workbook = openpyxl.load_workbook(filename)

    addresses_sheet = workbook["Адреса"]
    coordinates_sheet = workbook["Координаты"]

    addresses = [
        row[0]
        for row in addresses_sheet.iter_rows(min_row=2, values_only=True)
        if row[0]
    ]

    coordinates = [
        row[0]
        for row in coordinates_sheet.iter_rows(min_row=2, values_only=True)
        if row[0]
    ]

    return addresses, coordinates


def save_result(service, request, result, quality, status, elapsed):

    file_exists = os.path.exists("results.csv")

    with open("results.csv", "a", newline="", encoding="utf-8-sig") as file:

        writer = csv.writer(file)

        if not file_exists:
            writer.writerow([
                "Service",
                "Request",
                "Result",
                "Quality",
                "HTTP Status",
                "Response Time (ms)"
            ])

        writer.writerow([
            service,
            request,
            result,
            quality,
            status,
            round(elapsed * 1000, 2)
        ])

def update_gigachat_token():

    expire = int(os.getenv("GIGACHAT_TIME") or 0)

    if expire > int(time.time()):
        return

    headers = {
        "Authorization": f"Basic {os.getenv('GIGACHAT_AUTH_KEY')}",
        "RqUID": "12345678-1234-1234-1234-123456789012",
        "Content-Type": "application/x-www-form-urlencoded",
    }

    response = requests.post(
        "https://ngw.devices.sberbank.ru:9443/api/v2/oauth",
        headers=headers,
        data={
            "scope": os.getenv("GIGACHAT_SCOPE")
        },
        verify=False,
    )

    data = response.json()

    set_key(".env", "GIGACHAT_TOKEN", data["access_token"])
    set_key(".env", "GIGACHAT_TIME", str(data["expires_at"])[:-3])

    print("GigaChat token updated.")

def request_yandex(query, is_address):
    if is_address:
        query = query.replace(" ", "+")

    start = time.perf_counter()
    retries = 3

    for attempt in range(retries):
        try:
            response = requests.get(
                "https://geocode-maps.yandex.ru/v1/",
                params={
                    "apikey": os.getenv("YANDEX_API_KEY"),
                    "geocode": query,
                    "format": "json",
                    "lang": "ru_RU"
                },
                timeout=10,
            )

            elapsed = time.perf_counter() - start

            data = response.json()

            geo_object = data["response"]["GeoObjectCollection"]["featureMember"][0]["GeoObject"]

            if is_address:
                result = " ".join(geo_object["Point"]["pos"].split()[::-1])
            else:
                postal = geo_object["metaDataProperty"]["GeocoderMetaData"].get(
                    "postal_code", ""
                )
                result = f"{postal}, {geo_object['metaDataProperty']['GeocoderMetaData']['text']}"

            quality = geo_object["metaDataProperty"]["GeocoderMetaData"]["precision"]

            return result, quality, response.status_code, elapsed

        except Exception as e:
            if attempt < retries - 1:
                time.sleep(1)
                continue
            elapsed = time.perf_counter() - start
            return "", f"network error: {e}", 0, elapsed

def request_dadata(query, is_address):

    headers = {
        "Authorization": f"Token {os.getenv('DADATA_API_KEY')}",
        "X-Secret": os.getenv("DADATA_SECRET"),
        "Content-Type": "application/json"
    }

    if is_address:
        url = "https://cleaner.dadata.ru/api/v1/clean/address"
        payload = [query]
    else:
        lat, lon = map(float, reversed(query.split(",")))
        url = "https://suggestions.dadata.ru/suggestions/api/4_1/rs/geolocate/address"
        payload = {"lat": lat, "lon": lon}

    start = time.perf_counter()
    retries = 3

    for attempt in range(retries):
        try:
            response = requests.post(url, headers=headers, json=payload, timeout=10)
            elapsed = time.perf_counter() - start
            data = response.json()

            qc_geo_mapping = {
                0: "Точные координаты дома",
                1: "Ближайший дом",
                2: "Улица",
                3: "Населенный пункт",
                4: "Город",
                5: "Координаты не определены"
            }

            if is_address:
                result = data[0]["geo_lat"] + " " + data[0]["geo_lon"]
                quality = qc_geo_mapping.get(data[0]["qc_geo"], "")
            else:
                if len(data.get("suggestions", [])) == 0:
                    return "", "", response.status_code, elapsed
                suggestion = data["suggestions"][0]
                result = suggestion["unrestricted_value"]
                quality = qc_geo_mapping.get(suggestion["data"]["qc_geo"], "")

            return result, quality, response.status_code, elapsed

        except Exception as e:
            if attempt < retries - 1:
                time.sleep(1)
                continue
            elapsed = time.perf_counter() - start
            return "", f"network error: {e}", 0, elapsed

def request_gigachat(query, is_address):

    if is_address:

        prompt = (
            f"Определи координаты адреса '{query}'. "
            "Верни только координаты в формате: latitude longitude."
        )

    else:

        prompt = (
            f"Определи адрес по координатам {query}. "
            "Верни только полный почтовый адрес."
        )

    headers = {
        "Authorization": f"Bearer {os.getenv('GIGACHAT_TOKEN')}",
        "Content-Type": "application/json"
    }

    payload = {
        "model": "GigaChat-2",
        "messages": [
            {
                "role": "user",
                "content": prompt
            }
        ],
        "stream": False
    }

    start = time.perf_counter()
    retries = 3

    for attempt in range(retries):
        try:
            response = requests.post(
                "https://api.giga.chat/v1/chat/completions",
                headers=headers,
                json=payload,
                verify=False,
                timeout=10,
            )

            elapsed = time.perf_counter() - start
            data = response.json()
            result = data["choices"][0]["message"]["content"]
            return result, "-", response.status_code, elapsed

        except Exception as e:
            if attempt < retries - 1:
                time.sleep(1)
                continue
            elapsed = time.perf_counter() - start
            return "", f"network error: {e}", 0, elapsed

def calculate_statistics():

    stats = defaultdict(list)

    with open("results.csv", encoding="utf-8-sig") as file:

        reader = csv.DictReader(file)

        for row in reader:

            service = row["Service"]

            response_time = float(row["Response Time (ms)"])

            stats[service].append(response_time)

    with open("statistics.csv", "w", newline="", encoding="utf-8-sig") as file:

        writer = csv.writer(file)

        writer.writerow([
            "Service",
            "Requests",
            "Average (ms)",
            "Min (ms)",
            "Max (ms)"
        ])

        for service, values in stats.items():

            writer.writerow([
                service,
                len(values),
                round(sum(values) / len(values), 2),
                round(min(values), 2),
                round(max(values), 2),
            ])

if __name__ == "__main__":

    warnings.filterwarnings("ignore")

    load_dotenv()

    try:
        update_gigachat_token()
    except Exception as e:
        print(f"GigaChat token error: {e}")

    addresses, coordinates = read_excel("Геоданные.xlsx")

    print("Address geocoding...")

    for address in addresses:

        result = request_yandex(address, True)
        save_result("Yandex", address, *result)

        result = request_dadata(address, True)
        save_result("DaData", address, *result)

        result = request_gigachat(address, True)
        save_result("GigaChat", address, *result)

        time.sleep(1)

    print("Reverse geocoding...")

    for coords in coordinates:

        result = request_yandex(coords, False)
        save_result("Yandex", coords, *result)

        result = request_dadata(coords, False)
        save_result("DaData", coords, *result)

        result = request_gigachat(coords, False)
        save_result("GigaChat", coords, *result)

        time.sleep(1)

    print("Done!")

    calculate_statistics()

    print("Statistics saved.")