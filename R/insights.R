#' Performance insights / reports
#'
#' Retrieve simple performance reports (weekly, monthly) for a given account.
#'
#' @param session An `AvanzaSession` object.
#' @param account_id Character, the account id to retrieve the report for.
#' @param period Character, report period. One of `\"one_week\"`, `\"one_month\"`. Defaults to `\"one_week\"`.
#' @return A tibble with columns: `period`, `roi_pct`, `trades`, `win_rate_pct`, `total_pnl`, `avg_trade`.
#' @examples
#' \dontrun{
#' session <- avanza_auth(\"my_user\", \"my_password\", \"JBSWY3DPEHPK3PXP\")
#' report <- avanza_insights(session, account_id = \"12345678\", period = \"one_week\")
#' }
#' @export
avanza_insights <- function(session, account_id, period = c(\"one_week\", \"one_month\")) {
  stopifnot(inherits(session, \"AvanzaSession\"))
  period <- match.arg(period)

  # The API path /reports/{accountId}?period=one_week is a plausible mapping
  path <- sprintf(\"reports/%s\", account_id)
  query <- list(period = period)

  parsed <- tryCatch(
    avanza_request(session = session, method = \"GET\", path = path, query = query),
    error = function(e) rlang::abort(sprintf(\"Failed to fetch insights: %s\", conditionMessage(e)))
  )

  # Normalize response - support a few shapes
  rpt <- parsed$result %||% parsed$data %||% parsed$report %||% parsed

  # safe extraction with defaults
  period_label <- rpt$period %||% period
  roi_pct <- as.numeric(rpt$roiPct %||% rpt$roi_pct %||% rpt$roi %||% NA_real_)
  trades <- as.integer(rpt$trades %||% rpt$tradeCount %||% 0)
  win_rate_pct <- as.numeric(rpt$winRatePct %||% rpt$win_rate_pct %||% NA_real_)
  total_pnl <- as.numeric(rpt$totalPnl %||% rpt$total_pnl %||% rpt$totalProfitLoss %||% NA_real_)
  avg_trade <- if (trades > 0) total_pnl / trades else NA_real_

  dplyr::as_tibble(list(
    period = as.character(period_label),
    roi_pct = roi_pct,
    trades = trades,
    win_rate_pct = win_rate_pct,
    total_pnl = total_pnl,
    avg_trade = avg_trade
  ))
}
