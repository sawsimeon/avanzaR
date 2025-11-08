#' Detailed positions / holdings
#'
#' Retrieve a detailed list of holdings for an account.
#'
#' @param session An `AvanzaSession` object.
#' @param account_id Character, the account id to list positions for. If NULL the
#'   function may return positions across all accounts depending on the API.
#' @return A tibble with columns: `instrument`, `quantity`, `avg_price`, `market_value`, `pnl`.
#' @examples
#' \dontrun{
#' session <- avanza_auth(\"my_user\", \"my_password\", \"JBSWY3DPEHPK3PXP\")
#' positions <- avanza_positions(session, account_id = \"12345678\")
#' }
#' @export
avanza_positions <- function(session, account_id = NULL) {
  stopifnot(inherits(session, \"AvanzaSession\"))

  path <- if (!is.null(account_id)) {
    sprintf(\"customer/accounts/%s/positions\", account_id)
  } else {
    \"customer/positions\"
  }

  parsed <- tryCatch(
    avanza_request(session = session, method = \"GET\", path = path),
    error = function(e) rlang::abort(sprintf(\"Failed to fetch positions: %s\", conditionMessage(e)))
  )

  items <- parsed$positions %||% parsed$data %||% parsed$result %||% parsed

  # Normalize into list of rows
  rows <- lapply(items, function(it) {
    instr <- as.character(it$instrumentName %||% it$instrument_name %||% it$name %||% it$symbol %||% \"\")
    quantity <- as.numeric(it$quantity %||% it$qty %||% it$amount %||% 0)
    avg_price <- as.numeric(it$avgPrice %||% it$avg_price %||% it$averagePrice %||% NA_real_)
    market_value <- as.numeric(it$marketValue %||% it$market_value %||% it$value %||% NA_real_)
    pnl <- as.numeric(it$profitLoss %||% it$pnl %||% it$unrealizedPnl %||% NA_real_)

    list(
      instrument = instr,
      quantity = quantity,
      avg_price = avg_price,
      market_value = market_value,
      pnl = pnl
    )
  })

  if (length(rows) == 0) {
    return(dplyr::as_tibble(list(
      instrument = character(0),
      quantity = numeric(0),
      avg_price = numeric(0),
      market_value = numeric(0),
      pnl = numeric(0)
    )))
  }

  df <- do.call(rbind, lapply(rows, function(x) {
    data.frame(
      instrument = x$instrument,
      quantity = as.numeric(x$quantity),
      avg_price = as.numeric(x$avg_price),
      market_value = as.numeric(x$market_value),
      pnl = as.numeric(x$pnl),
      stringsAsFactors = FALSE
    )
  }))

  dplyr::as_tibble(df)
}
