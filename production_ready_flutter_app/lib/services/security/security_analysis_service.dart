import 'application_security_tool.dart';
import 'security_models.dart';
import 'security_repository.dart';

class SecurityAnalysisService {
  const SecurityAnalysisService({
    ApplicationSecurityTool? tool,
    SecurityFindingRepository? repository,
  })  : _tool = tool ?? const ApplicationSecurityTool(),
        _repository = repository ?? const SecurityFindingRepository();

  final ApplicationSecurityTool _tool;
  final SecurityFindingRepository _repository;

  Future<AnalysisReport> analyse(ScanRequest request) async {
    final findings = await _repository.fetchFindings(request);
    return _tool.analyze(findings, request);
  }
}
