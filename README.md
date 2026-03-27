# audiodockr

Flutter music player UI backed by a `yt-dlp` API.

## Start the yt-dlp backend

Create a Python environment, then install the backend requirements:

```bash
pip install -r backend/requirements.txt
```

Start the API server:

```bash
uvicorn backend.app:app --host 0.0.0.0 --port 8000
```

## Run the Flutter app

Launch Flutter with your backend URL:

```bash
flutter run --dart-define=AUDIODOCKR_API_BASE_URL=http://YOUR_COMPUTER_IP:8000
```

For Android emulators, `10.0.2.2` usually points back to the host machine:

```bash
flutter run --dart-define=AUDIODOCKR_API_BASE_URL=http://10.0.2.2:8000
```

For a physical Android phone, use your computer's LAN IP and make sure both devices are on the same network.

## API endpoints

- `GET /health`
- `POST /search`
- `POST /extract`
