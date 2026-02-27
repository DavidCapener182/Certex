export function rankBidEntries(bids = []) {
  return [...(Array.isArray(bids) ? bids : [])].sort((first, second) => {
    const scoreDelta = Number(second?.rankScore || 0) - Number(first?.rankScore || 0);
    if (scoreDelta !== 0) {
      return scoreDelta;
    }

    const qualityDelta = Number(second?.qualityScore || 0) - Number(first?.qualityScore || 0);
    if (qualityDelta !== 0) {
      return qualityDelta;
    }

    const priceDelta = Number(first?.totalExVat || 0) - Number(second?.totalExVat || 0);
    if (priceDelta !== 0) {
      return priceDelta;
    }

    return String(first?.id || '').localeCompare(String(second?.id || ''));
  });
}

export function summarizeRiskSignals(signals = []) {
  const safeSignals = Array.isArray(signals) ? signals : [];
  const summary = safeSignals.reduce(
    (accumulator, signal) => {
      const normalizedLevel = String(signal?.riskLevel || 'low').toLowerCase();
      if (normalizedLevel === 'high') {
        accumulator.high += 1;
      } else if (normalizedLevel === 'medium') {
        accumulator.medium += 1;
      } else {
        accumulator.low += 1;
      }
      return accumulator;
    },
    { high: 0, medium: 0, low: 0 }
  );

  const overallLevel = summary.high > 0 ? 'high' : summary.medium > 0 ? 'medium' : 'low';
  return {
    ...summary,
    total: summary.high + summary.medium + summary.low,
    overallLevel,
  };
}

export function summarizeReleaseGateStatus(gates = []) {
  const safeGates = Array.isArray(gates) ? gates : [];
  const pending = safeGates.filter((gate) => String(gate?.status || '').toLowerCase() === 'pending').length;
  const failed = safeGates.filter((gate) => String(gate?.status || '').toLowerCase() === 'failed').length;
  const passed = safeGates.filter((gate) => String(gate?.status || '').toLowerCase() === 'passed').length;

  return {
    pending,
    failed,
    passed,
    total: safeGates.length,
    releaseReadiness: failed > 0 ? 'blocked' : pending > 0 ? 'pending' : 'ready',
  };
}

