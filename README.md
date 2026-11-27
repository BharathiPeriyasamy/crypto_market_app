# Crypto Market App

Crypto Market App is a cryptocurrency tracking application built using **Flutter** and **Django**. It helps users view cryptocurrency prices, market details, and price charts.

The Django backend connects to the CoinGecko API to get live crypto data. It also uses cached data and mock data when the API is unavailable.

## Technologies Used

- **Frontend:** Flutter
- **Backend:** Django (Python)
- **API:** CoinGecko API
- **State Management:** Provider

## Requirements

Before running the project, make sure you have:

- Python 3.10 or above
- Flutter SDK
- Dart 3.8.1 or above
- Android Studio or VS Code

## 1. Run the Backend

Open a terminal and go to the backend folder:

```bash
cd backend
```

Create a virtual environment:

```bash
python -m venv venv
```

Activate it on Windows:

```bash
venv\Scripts\activate
```

Install the required packages:

```bash
pip install -r requirements.txt
```

Start the Django server:

```bash
python manage.py runserver
```

The backend will run at:

`http://127.0.0.1:8000`

To check whether the backend is working, open:

`http://127.0.0.1:8000/api/health`

## 2. Run the Flutter App

Open another terminal and go to the Flutter project:

```bash
cd mobile_frontend
```

Install the packages:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

## API Configuration

The app uses the deployed backend by default.

If you want to connect to your local backend, use the following commands.

**Android Emulator:**

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

**Chrome:**

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api
```

**iOS Simulator:**

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api
```

## API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/health` | Check backend status |
| GET | `/api/coins` | Get cryptocurrency list |
| GET | `/api/coins/{coin_id}` | Get coin details |
| GET | `/api/coins/{coin_id}/chart` | Get price chart |
| GET | `/api/global` | Get global market data |

## Notes

- The app uses CoinGecko to get cryptocurrency data.
- If the live API is unavailable, cached or mock data is displayed.
- A CoinGecko API key can be added to improve API access.
- Set `MOCK=1` in the backend environment to use mock data without making API calls.
