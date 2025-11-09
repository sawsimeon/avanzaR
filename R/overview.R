#' Portfolio overview
#'
#' Retrieve account balances, positions counts and buying power for all accounts
#' associated with the authenticated user.
#'
#' @param session An `AvanzaSession` object returned by `avanza_auth()` / `avanza_session()`.
#' @return A tibble with columns: `account_id`, `name`, `total_value`, `buying_power`,
#'   `positions`, `instruments`, `unrealized_pnl`.
#' @examples
#' \dontrun{
#' session <- avanza_auth(\"my_user\", \"my_password\", \"JBSWY3DPEHPK3PXP\")
#' overview <- avanza_overview(session)
#' }
#' @export
avanza_overview <- function(session) {
  stopifnot(inherits(session, \"AvanzaSession\"))

  parsed <- tryCatch(
    avanza_request(session = session, method = \"GET\", path = \"customer/accounts\"),
    error = function(e) rlang::abort(sprintf(\"Failed to fetch overview: %s\", conditionMessage(e)))
  )

  # Accept a few possible response shapes
  accounts <- NULL
  if (!is.null(parsed$accounts)) {
    accounts <- parsed$accounts
  } else if (!is.null(parsed$data)) {
    accounts <- parsed$data
  } else if (is.list(parsed) && length(parsed) > 0 && all(vapply(parsed, is.list, logical(1)))) {
    accounts <- parsed
  } else {
    rlang::abort(\"Unexpected API response while fetching overview\")
  }

  # Normalize into tibble
  out <- lapply(accounts, function(acc) {
    # Try to pick fields from common key names
    account_id <- acc$accountId %||% acc$account_id %||% acc$id %||% ""
    name <- acc$name %||% acc$accountName %||% acc$accountType %||% ""
    total_value <- as.numeric(acc$totalValue %||% acc$total_value %||% acc$balance %||% NA_real_)
    buying_power <- as.numeric(acc$buyingPower %||% acc$buying_power %||% acc$available %||% NA_real_)
    positions <- as.integer(length(acc$positions %||% acc$holdings %||% (acc$positionCount %||% NA)))
    instruments <- as.integer(acc$instruments %||% acc$instrumentCount %||% positions)
    unrealized_pnl <- as.numeric(acc$unrealizedPnl %||% acc$unrealized_pnl %||% acc$unrealizedProfitLoss %||% NA_real_)

    list(
      account_id = as.character(account_id),
      name = as.character(name),
      total_value = total_value,
      buying_power = buying_power,
      positions = positions,
      instruments = instruments,
      unrealized_pnl = unrealized_pnl
    )
  })

  df <- dplyr::as_tibble(do.call(rbind, lapply(out, function(x) {
    # ensure numeric types are preserved when coercing from list
    data.frame(
      account_id = x$account_id,
      name = x$name,
      total_value = as.numeric(x$total_value),
      buying_power = as.numeric(x$buying_power),
      positions = as.integer(x$positions),
      instruments = as.integer(x$instruments),
      unrealized_pnl = as.numeric(x$unrealized_pnl),
      stringsAsFactors = FALSE
    )
  })))

  df
}
