/// Declaración independiente de Flutter para formularios de mantenimiento.
class FormFieldSpec {
  const FormFieldSpec(this.key, this.label, {this.kind = 'text', this.required = true, this.options, this.table, this.optionLabel = 'name'});
  final String key, label, kind, optionLabel;
  final bool required;
  final List<String>? options;
  final String? table;
}
