/*
 * AI 生成 —— 本地单元测试套件入口（hypium）
 * 运行方式：工程根目录执行 hvigorw test -p module=entry
 */
import ruleEngineTest from './RuleEngine.test';
import libraryTest from './Library.test';
import upgradeTest from './Upgrade.test';

export default function testsuite(): void {
  ruleEngineTest();
  libraryTest();
  upgradeTest();
}
