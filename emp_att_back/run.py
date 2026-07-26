from src import create_app
import os

app = create_app()

if __name__ == '__main__':
    # Render provides a PORT env variable. Default to 5000 for local dev.
    port = int(os.environ.get("PORT", 5000))
    is_debug = os.environ.get("FLASK_DEBUG", "False").lower() == "true"
    app.run(host='0.0.0.0', port=port, debug=is_debug)