//// This module provides an easy way to reference
//// [HTTP status codes](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)
//// and some extra utilities for working with them.
////
//// ```
//// status.not_found
//// |> status.classify
//// // -> ClientError
//// ```

/// HTTP status codes are divided into 5 main groups:
/// - Informational responses (100 – 199)
/// - Successful responses (200 – 299)
/// - Redirection messages (300 – 399)
/// - Client error responses (400 – 499)
/// - Server error responses (500 – 599)
pub type StatusType {
  Informational
  Successful
  Redirection
  ClientError
  ServerError
}

/// Classify a status code into a [`StatusType`](#StatusType).
pub fn classify(status: Int) -> StatusType {
  case status {
    _ if status >= 500 -> ServerError
    _ if status >= 400 -> ClientError
    _ if status >= 300 -> Redirection
    _ if status >= 200 -> Successful
    _ -> Informational
  }
}

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/100)
pub const continue = 100

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/101)
pub const switching_protocols = 101

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/102)
pub const processing = 102

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/103)
pub const early_hints = 103

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/200)
pub const ok = 200

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/201)
pub const created = 201

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/202)
pub const accepted = 202

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/203)
pub const non_authoritative_information = 203

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/204)
pub const no_content = 204

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/205)
pub const reset_content = 205

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/206)
pub const partial_content = 206

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/207)
pub const multi_status = 207

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/208)
pub const already_reported = 208

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/226)
pub const im_used = 226

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/300)
pub const multiple_choices = 300

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/301)
pub const moved_permanently = 301

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/302)
pub const found = 302

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/303)
pub const see_other = 303

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/304)
pub const not_modified = 304

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/305)
pub const use_proxy = 305

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/307)
pub const temporary_redirect = 307

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/308)
pub const permanent_redirect = 308

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/400)
pub const bad_request = 400

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/401)
pub const unauthorized = 401

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/402)
pub const payment_required = 402

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/403)
pub const forbidden = 403

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/404)
pub const not_found = 404

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/405)
pub const method_not_allowed = 405

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/406)
pub const not_acceptable = 406

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/407)
pub const proxy_authentication_required = 407

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/408)
pub const request_timeout = 408

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/409)
pub const conflict = 409

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/410)
pub const gone = 410

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/411)
pub const length_required = 411

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/412)
pub const precondition_failed = 412

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/413)
pub const payload_too_large = 413

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/414)
pub const request_uri_too_long = 414

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/415)
pub const unsupported_media_type = 415

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/416)
pub const requested_range_not_satisfiable = 416

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/417)
pub const expectation_failed = 417

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/418)
pub const im_a_teapot = 418

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/421)
pub const misdirected_request = 421

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/422)
pub const unprocessable_entity = 422

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/423)
pub const locked = 423

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/424)
pub const failed_dependency = 424

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/426)
pub const upgrade_required = 426

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/428)
pub const precondition_required = 428

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/429)
pub const too_many_requests = 429

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/431)
pub const request_header_fields_too_large = 431

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/444)
pub const connection_closed_without_response = 444

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/451)
pub const unavailable_for_legal_reasons = 451

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/499)
pub const client_closed_request = 499

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/500)
pub const internal_server_error = 500

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/501)
pub const not_implemented = 501

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/502)
pub const bad_gateway = 502

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/503)
pub const service_unavailable = 503

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/504)
pub const gateway_timeout = 504

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/505)
pub const http_version_not_supported = 505

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/506)
pub const variant_also_negotiates = 506

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/507)
pub const insufficient_storage = 507

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/508)
pub const loop_detected = 508

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/510)
pub const not_extended = 510

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/511)
pub const network_authentication_required = 511

/// [Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/599)
pub const network_connect_timeout_error = 599
