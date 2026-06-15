// Wraps fetch for JSON APIs: sets Accept header, throws on HTTP errors with .status attached.
export async function fetchJSON(url, { signal, ...options } = {}) {
  const response = await fetch(url, {
    headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" },
    signal,
    ...options
  })
  if (!response.ok) {
    const error = new Error(`HTTP ${response.status}`)
    error.status = response.status
    throw error
  }
  return response.json()
}
