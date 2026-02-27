import { describe, expect, it } from 'vitest';
import { rankBidEntries, summarizeReleaseGateStatus, summarizeRiskSignals } from './opsScoring';

describe('rankBidEntries', () => {
  it('orders by rank score then quality then lower price', () => {
    const ranked = rankBidEntries([
      { id: 'B-2', rankScore: 90, qualityScore: 92, totalExVat: 350 },
      { id: 'B-1', rankScore: 90, qualityScore: 92, totalExVat: 330 },
      { id: 'B-3', rankScore: 88, qualityScore: 99, totalExVat: 320 },
    ]);

    expect(ranked.map((item) => item.id)).toEqual(['B-1', 'B-2', 'B-3']);
  });
});

describe('summarizeRiskSignals', () => {
  it('builds totals and overall level from risk levels', () => {
    const summary = summarizeRiskSignals([
      { riskLevel: 'medium' },
      { riskLevel: 'high' },
      { riskLevel: 'low' },
      { riskLevel: 'high' },
    ]);

    expect(summary).toEqual({
      high: 2,
      medium: 1,
      low: 1,
      total: 4,
      overallLevel: 'high',
    });
  });
});

describe('summarizeReleaseGateStatus', () => {
  it('returns blocked when any gate failed', () => {
    const summary = summarizeReleaseGateStatus([
      { status: 'passed' },
      { status: 'failed' },
      { status: 'pending' },
    ]);

    expect(summary.releaseReadiness).toBe('blocked');
    expect(summary.failed).toBe(1);
    expect(summary.pending).toBe(1);
    expect(summary.passed).toBe(1);
  });

  it('returns ready when all gates passed', () => {
    const summary = summarizeReleaseGateStatus([{ status: 'passed' }, { status: 'passed' }]);
    expect(summary.releaseReadiness).toBe('ready');
    expect(summary.total).toBe(2);
  });
});

