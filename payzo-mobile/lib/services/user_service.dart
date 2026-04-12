import 'dart:convert';
import '../models/user.dart';
import 'api_service.dart';

class UserService {
  final ApiService _api;
  UserService(this._api);

  Future<UserModel> updateProfile({
    String? nickname,
    String? gender,
    String? dateOfBirth,
    String? mobile,
    String? address,
  }) async {
    final data = <String, dynamic>{};
    if (nickname != null) data['nickname'] = nickname;
    if (gender != null) data['gender'] = gender;
    if (dateOfBirth != null) data['date_of_birth'] = dateOfBirth;
    if (mobile != null) data['mobile'] = mobile;
    if (address != null) data['address'] = address;

    final res = await _api.put('/user/profile', data: data);
    final userData = res.data['data']['user'];
    final user = UserModel.fromJson(userData);
    
    // Update stored user data
    await _api.saveUser(jsonEncode(userData));
    
    return user;
  }

  Future<UserModel> getProfile() async {
    final res = await _api.get('/user/profile');
    final userData = res.data['data']['user'];
    final user = UserModel.fromJson(userData);
    
    // Update stored user data
    await _api.saveUser(jsonEncode(userData));
    
    return user;
  }
}