import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'models.dart';
import 'supabase_service.dart';

class ChangeSubScreen extends StatefulWidget {
  final Subscription subscription;
  const ChangeSubScreen({super.key, required this.subscription});

  @override
  State<ChangeSubScreen> createState() => _ChangeSubScreenState();
}

class _ChangeSubScreenState extends State<ChangeSubScreen> {
  bool _isTrial = false;
  bool _isFamily = false;

  String? _nameError;
  String? _priceError;
  String? _membersError;
  String? _trialDateError;
  String? _trialPriceError;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _trialEndDateController = TextEditingController();
  final TextEditingController _trialPriceController = TextEditingController();
  final TextEditingController _membersController = TextEditingController(text: '2');

  String _selectedCategory = 'Кино';
  String _selectedPeriod = 'month';
  String _selectedBillingDate = '10 число';
  DateTime? _selectedTrialEndDate;

  static const Color _primaryColor = Color(0xFF6C47FF);
  static const Color _backgroundColor = Color(0xFFF5F5F7);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textGray = Color(0xFF6B6B6B);
  static const Color _dangerColor = Color(0xFFE74C3C);

  static const List<String> _categories = [
    'Кино', 'Книги', 'Музыка', 'Образование',
    'Работа', 'Развлечения', 'Связь', 'Спорт', 'Другое',
  ];

  double get _sharePrice {
    final price = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;
    final members = int.tryParse(_membersController.text) ?? 1;
    if (members <= 0) return price;
    return price / members;
  }

  @override
  void initState() {
    super.initState();
    final sub = widget.subscription;
    _nameController.text = sub.name;
    _priceController.text = sub.price.toStringAsFixed(0);
    _isFamily = sub.hasFamily;
    _isTrial = sub.isTrial;
    _selectedCategory = sub.category;
    _selectedPeriod = sub.billingPeriod;
    _selectedBillingDate = '${sub.billingDate} число';
    _selectedTrialEndDate = sub.trialEndDate;

    if (_isTrial) {
      _trialPriceController.text = sub.trialPriceAfter?.toStringAsFixed(0) ?? '';
      if (sub.trialEndDate != null) {
        const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
        _trialEndDateController.text = '${sub.trialEndDate!.day} ${months[sub.trialEndDate!.month - 1]}';
      }
    }

    if (_isFamily && sub.familyGroupId != null) {
      SupabaseService.getFamilyGroup(sub.familyGroupId!).then((group) {
        if (group != null && mounted) {
          _membersController.text = group.members.toString();
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _trialEndDateController.dispose();
    _trialPriceController.dispose();
    _membersController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    bool isValid = true;

    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = 'Введите название сервиса');
      isValid = false;
    } else {
      setState(() => _nameError = null);
    }

    if (_isTrial) {
      if (_trialEndDateController.text.isEmpty) {
        setState(() => _trialDateError = 'Укажите дату окончания');
        isValid = false;
      } else {
        setState(() => _trialDateError = null);
      }

      final trialPriceText = _trialPriceController.text.trim();
      if (trialPriceText.isEmpty) {
        setState(() => _trialPriceError = 'Укажите стоимость');
        isValid = false;
      } else if (!RegExp(r'^\d+([,.]\d+)?$').hasMatch(trialPriceText)) {
        setState(() => _trialPriceError = 'Некорректная сумма');
        isValid = false;
      } else {
        setState(() => _trialPriceError = null);
      }
    }

    final priceText = _priceController.text.trim();
    if (priceText.isEmpty) {
      setState(() => _priceError = 'Введите стоимость');
      isValid = false;
    } else if (!RegExp(r'^\d+([,.]\d+)?$').hasMatch(priceText)) {
      setState(() => _priceError = 'Некорректная сумма');
      isValid = false;
    } else {
      final price = double.tryParse(priceText.replaceAll(',', '.'));
      if (price == null || price <= 0) {
        setState(() => _priceError = 'Сумма должна быть больше 0');
        isValid = false;
      } else {
        setState(() => _priceError = null);
      }
    }

    if (_isFamily) {
      final membersText = _membersController.text.trim();
      final members = int.tryParse(membersText);
      if (membersText.isEmpty) {
        setState(() => _membersError = 'Введите количество участников');
        isValid = false;
      } else if (members == null) {
        setState(() => _membersError = 'Некорректное число');
        isValid = false;
      } else if (members < 2) {
        setState(() => _membersError = 'Минимум 2 участника');
        isValid = false;
      } else if (members > 10) {
        setState(() => _membersError = 'Максимум 10 участников');
        isValid = false;
      } else {
        setState(() => _membersError = null);
      }
    } else {
      setState(() => _membersError = null);
    }

    return isValid;
  }

   Future<void> _saveSubscription() async {
    if (!_validateForm()) return;

    final price = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;
    final billingDate = int.tryParse(_selectedBillingDate.replaceAll(' число', '')) ?? 10;

    setState(() => _isLoading = true);

    try {
      final userId = SupabaseService.client.auth.currentUser!.id;
      String? familyGroupId = widget.subscription.familyGroupId;

      if (_isFamily && familyGroupId == null) {
        final members = int.parse(_membersController.text);
        final group = await SupabaseService.createFamilyGroup(userId, members);
        familyGroupId = group.id;
        await Future.delayed(const Duration(milliseconds: 100));
        await SupabaseService.addFamilyMember(group.id, userId, 'owner');
      } else if (_isFamily && familyGroupId != null) {
        final members = int.parse(_membersController.text);
        await SupabaseService.updateFamilyGroupMembers(familyGroupId, members);
      }

      final updatedSub = Subscription(
        id: widget.subscription.id,
        ownerId: userId,
        name: _nameController.text.trim(),
        category: _selectedCategory,
        price: price,
        billingPeriod: _selectedPeriod,
        billingDate: billingDate,
        isTrial: _isTrial,
        trialEndDate: _selectedTrialEndDate,
        trialPriceAfter: _isTrial ? (double.tryParse(_trialPriceController.text.replaceAll(',', '.')) ?? 0) : null,
        familyGroupId: _isFamily ? familyGroupId : null,
        createdAt: widget.subscription.createdAt,
      );

      await SupabaseService.updateSubscription(updatedSub);

      // ✅ Обновляем reminder при изменении даты списания
      if (widget.subscription.billingDate != billingDate) {
        await SupabaseService.updateReminder(widget.subscription.id, billingDate);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Подписка обновлена!'), backgroundColor: _primaryColor));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Ошибка: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _primaryColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: _textDark), onPressed: () => Navigator.pop(context)),
        title: const Text('Редактирование', style: TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSwitchCard(
              title: 'Это пробный период',
              subtitle: 'Включим защиту от автопродления',
              value: _isTrial,
              onChanged: (v) {
                setState(() {
                  _isTrial = v;
                  // ✅ Очистка полей и ошибок при выключении тумблера
                  if (!v) {
                    _trialEndDateController.clear();
                    _trialPriceController.clear();
                    _trialDateError = null;
                    _trialPriceError = null;
                    _selectedTrialEndDate = null;
                  }
                });
              },
            ),
            const SizedBox(height: 12),

            if (_isTrial) ...[
              Row(
                children: [
                  Expanded(child: _buildDateField(
                    label: 'Дата окончания',
                    controller: _trialEndDateController,
                    onDatePicked: (date) {
                      setState(() {
                        _selectedTrialEndDate = date;
                        _trialDateError = null; // ✅ Сброс ошибки при выборе даты
                      });
                    },
                    errorText: _trialDateError,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildRubField(
                    label: 'Стоимость после',
                    controller: _trialPriceController,
                    hintText: '699',
                    errorText: _trialPriceError,
                    allowDecimal: true,
                    onChanged: () => setState(() => _trialPriceError = null), // ✅ Сброс именно trialPriceError
                  )),
                ],
              ),
              const SizedBox(height: 12),
            ],

            _buildField(label: 'Название сервиса', controller: _nameController, errorText: _nameError),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: _buildDropdownField(label: 'Категория', value: _selectedCategory, items: _categories, onChanged: (v) => setState(() => _selectedCategory = v!))),
                const SizedBox(width: 12),
                Expanded(child: _buildRubField(
                  label: 'Стоимость',
                  controller: _priceController,
                  hintText: '699',
                  errorText: _priceError,
                  allowDecimal: true,
                  onChanged: () => setState(() => _priceError = null), // ✅ Сброс именно priceError
                )),
              ],
            ),
            const SizedBox(height: 12),

            _buildDropdownField(label: 'Период списания', value: _selectedPeriod, items: ['month', '3months', '6months', 'year', 'week'], labels: ['Каждый месяц', 'Каждые 3 месяца', 'Каждые 6 месяцев', 'Каждый год', 'Каждую неделю'], onChanged: (v) => setState(() => _selectedPeriod = v!)),
            const SizedBox(height: 12),

            _buildDropdownField(label: 'Дата списания', value: _selectedBillingDate, items: List.generate(31, (i) => '${i + 1} число'), onChanged: (v) => setState(() => _selectedBillingDate = v!)),
            const SizedBox(height: 12),

            _buildSwitchCard(title: 'Семейный аудит', subtitle: 'Посчитаем расходы каждого участника', value: _isFamily, onChanged: (v) {
              setState(() { _isFamily = v; _membersError = null; });
            }),
            const SizedBox(height: 12),

            if (_isFamily) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  border: _membersError != null ? Border.all(color: _dangerColor, width: 1.5) : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Сколько участников (2-10)', style: TextStyle(fontSize: 14, color: _textGray)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _membersError != null ? _dangerColor : const Color(0xFFE8E8ED)),
                            ),
                            child: TextField(
                              controller: _membersController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, color: _textDark),
                              decoration: InputDecoration(
                                errorText: _membersError,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              onChanged: (_) => setState(() => _membersError = null),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Ваша доля', style: TextStyle(fontSize: 11, color: _textGray)),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(_sharePrice.toStringAsFixed(2).replaceAll('.', ','), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryColor)),
                                    const SizedBox(width: 2),
                                    const Text('₽', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primaryColor)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSubscription,
                style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Сохранить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSwitchCard({required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textDark)), const SizedBox(height: 2), Text(subtitle, style: TextStyle(fontSize: 12, color: _textGray))])),
          Switch(value: value, onChanged: onChanged, activeColor: _primaryColor, activeTrackColor: _primaryColor.withValues(alpha:0.3)),
        ],
      ),
    );
  }

  Widget _buildDateField({required String label, required TextEditingController controller, required ValueChanged<DateTime> onDatePicked, String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: _textGray)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 30)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: _primaryColor)), child: child!),
            );
            if (pickedDate != null) {
              const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
              setState(() {
                controller.text = '${pickedDate.day} ${months[pickedDate.month - 1]}';
                onDatePicked(pickedDate);
              });
            }
          },
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8, offset: const Offset(0, 2))],
              border: errorText != null ? Border.all(color: _dangerColor, width: 1.5) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(controller.text.isEmpty ? 'Выберите дату' : controller.text, style: TextStyle(fontSize: 15, color: controller.text.isEmpty ? _textGray : _textDark)),
                const Icon(Icons.calendar_today_outlined, size: 18, color: _textGray),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(errorText, style: const TextStyle(color: _dangerColor, fontSize: 12)),
        ],
      ],
    );
  }

  Widget _buildField({required String label, required TextEditingController controller, String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: _textGray)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8, offset: const Offset(0, 2))],
            border: errorText != null ? Border.all(color: _dangerColor, width: 1.5) : null,
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 15, color: _textDark),
            decoration: InputDecoration(
              errorText: errorText,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (_) => setState(() => _nameError = null),
          ),
        ),
      ],
    );
  }

  // ✅ Добавлен параметр onChanged для корректного сброса нужной ошибки
  Widget _buildRubField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    String? errorText,
    bool allowDecimal = false,
    VoidCallback? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: _textGray)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8, offset: const Offset(0, 2))],
            border: errorText != null ? Border.all(color: _dangerColor, width: 1.5) : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: allowDecimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
                  inputFormatters: [
                    if (allowDecimal) FilteringTextInputFormatter.allow(RegExp(r'^\d*([,.]?\d*)?$'))
                    else FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: const TextStyle(fontSize: 15, color: _textDark),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(color: _textGray),
                    errorText: errorText,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (_) => onChanged?.call(), // ✅ Вызываем переданный колбэк
                ),
              ),
              Padding(padding: const EdgeInsets.only(right: 16), child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, mainAxisSize: MainAxisSize.min, children: const [Text('₽', style: TextStyle(fontSize: 15, color: _textGray))])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({required String label, required String value, required List<String> items, List<String>? labels, required ValueChanged<String?> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: _textGray)),
        const SizedBox(height: 8),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8, offset: const Offset(0, 2))]),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : null,
              isExpanded: true,
              hint: Text((labels != null && items.contains(value)) ? labels[items.indexOf(value)] : value, style: const TextStyle(fontSize: 15, color: _textDark)),
              items: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final displayLabel = labels != null ? labels[index] : item;
                return DropdownMenuItem(value: item, child: Text(displayLabel, style: const TextStyle(fontSize: 15, color: _textDark)));
              }).toList(),
              onChanged: onChanged,
              icon: const Icon(Icons.keyboard_arrow_down, color: _textGray),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 70,
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.06), blurRadius: 10, offset: const Offset(0, -2))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.credit_card_outlined, 'Подписки', 0, isActive: true),
          _buildNavItem(Icons.build_outlined, 'Инструменты', 1),
          _buildNavItem(Icons.bar_chart_outlined, 'Аналитика', 2),
          _buildNavItem(Icons.person_outline, 'Профиль', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, {bool isActive = false}) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => HomeScreen(initialIndex: index)), (r) => false);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? _primaryColor : _textGray, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal, color: isActive ? _primaryColor : _textGray)),
          ],
        ),
      ),
    );
  }
}