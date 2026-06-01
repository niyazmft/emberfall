import urllib.request, json
try:
    req = urllib.request.urlopen("http://127.0.0.1:8000/api/pr-comments")
    print(req.read().decode('utf-8'))
except Exception as e:
    print(f"Error: {e}")
