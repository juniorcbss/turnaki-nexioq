/* eslint-disable */
export function handleSummary(data) {
  const summary = {
    metrics: data.metrics,
    scenarios: Object.keys(data.state?.scenarios || {})
  };
  return {
    'k6-summary.json': JSON.stringify(summary, null, 2)
  };
}


