import requests


url = "https://api.openai.com/v1/embeddings"

headers = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer openaiapikey",
}

data = {
    "input": ["Your text string goes here", "Another text string", "And a third one"],
    "model": "text-embedding-ada-002"
}

response = requests.post(url, headers=headers, json=data)

print(response.json())
