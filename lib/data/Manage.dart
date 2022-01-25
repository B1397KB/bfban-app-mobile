import 'Captcha.dart';

/// 裁判
class ManageStatus {
  late bool? load;
  late ManageData? data;

  ManageStatus({
    this.load,
    this.data,
  });
}

/// 裁判参数
class ManageData {
  // 描述内容
  late String? content;

  // 判决类型 如石锤
  late String? action;

  // 行为 如透视
  late String? cheatMethods;

  // 玩家id
  late String? toPlayerId;

  late Captcha? captcha;

  ManageData({
    this.captcha,
    this.content,
    this.action,
    this.cheatMethods,
    this.toPlayerId,
  });

  get toMap {
    return {
      "data": {
        "content": content,
        "action": action,
        "cheatMethods": cheatMethods,
        "toPlayerId": toPlayerId,
      },
      "encryptCaptcha": captcha!.hash,
      "captcha": captcha!.value,
    };
  }
}