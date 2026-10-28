// ...existing code...
  // ── GET /resend-code ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> resendCode() async {
    try {
      final response = await dio.post('/auth/resend-code');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Không thể gửi lại mã';
    }
  }

  // ── CHAT ────────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getConversations() async {
    try {
      final response = await dio.get('/chat/conversations');
      return response.data['conversations'];
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Lỗi tải hội thoại';
    }
  }

  static Future<List<dynamic>> getMessages(int otherId) async {
    try {
      final response = await dio.get('/chat/$otherId');
      return response.data['messages'];
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Lỗi tải tin nhắn';
    }
  }

  static Future<Map<String, dynamic>> sendMessage(int receiverId, String content) async {
    try {
      final response = await dio.post('/chat', data: {
        'receiver_id': receiverId,
        'content': content,
      });
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Lỗi gửi tin nhắn';
    }
  }

  // ── REPUTATION ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getReputation(int userId) async {
    try {
      final response = await dio.get('/auth/reputation/$userId');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Lỗi tải đánh giá';
    }
  }

  static Future<void> addReview(int targetId, int rating, String comment) async {
    try {
      await dio.post('/auth/reputation', data: {
        'target_id': targetId,
        'rating': rating,
        'comment': comment,
      });
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Lỗi gửi đánh giá';
    }
  }
}
// ...existing code...

