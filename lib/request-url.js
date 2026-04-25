export function buildAbsoluteUrl(request, pathnameWithSearch) {
  const forwardedProto = request.headers.get("x-forwarded-proto");
  const forwardedHost = request.headers.get("x-forwarded-host");

  if (forwardedProto && forwardedHost) {
    return new URL(pathnameWithSearch, `${forwardedProto}://${forwardedHost}`);
  }

  return new URL(pathnameWithSearch, request.url);
}
