String getUserFriendlyError(String rawError) {
  final lowerError = rawError.toLowerCase();
  
  if (lowerError.contains("socket") || 
      lowerError.contains("clientexception") || 
      lowerError.contains("connection refused")) {
    return "No internet connection. Please check your network.";
  }
  if (lowerError.contains("timeout")) {
    return "The connection timed out. Please try again.";
  }
  if (lowerError.contains("404")) {
    return "This chat could not be found.";
  }
  if (lowerError.contains("500")) {
    return "Server is having trouble. Try again later.";
  }
  
  // Default fallback
  return "Unable to load messages.";
}