from google.cloud import language_v1

def analyze_text(request):
    request_json = request.get_json(silent=True)
    request_args = request.args

    if request_json and 'comment' in request_json:
        text = request_json['comment']
    else:
        return "Error: No text provided.", 400

    client = language_v1.LanguageServiceClient()

    document = language_v1.Document(content=text, type_=language_v1.Document.Type.PLAIN_TEXT)
    sentiment = client.analyze_sentiment(request={"document": document}).document_sentiment

    result = {
        "text": text,
        "sentiment_score": sentiment.score,
        "sentiment_magnitude": sentiment.magnitude
    }

    return result

