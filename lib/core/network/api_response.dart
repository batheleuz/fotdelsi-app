class ApiResponse<T> {
  ApiResponse(this.code, this.message, this.data);

  String code;
  String message;
  T data;

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(json["code"], json["message"], json["data"]);
  }
}
