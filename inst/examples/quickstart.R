## Quickstart example for avanzaR
## Run interactively (this file is for examples only; do not store credentials here)

library(avanzaR)
library(totp)   # for two-factor authentication, if you use totp secrets

# Option 1: read credentials from environment (recommended)
# Sys.setenv(AVANZA_USER = "my_user")
# Sys.setenv(AVANZA_PASS = "my_password")
# Sys.setenv(AVANZA_TOTP = "JBSWY3DPEHPK3PXP")

# 1. Authenticate
session <- avanza_auth(
  username   = Sys.getenv("AVANZA_USER"),
  password   = Sys.getenv("AVANZA_PASS"),
  totp_secret = Sys.getenv("AVANZA_TOTP")
)

print(session)

# 2. Get portfolio overview
overview <- avanza_overview(session)
print(overview)

# 3. Performance report
if (nrow(overview) > 0) {
  account_id <- overview$account_id[1]
  report <- avanza_insights(session, account_id = account_id, period = "one_week")
  print(report)
}

# 4. Quote example (replace with a real orderbook id)
# quote <- avanza_quote(session, id = "199694")
# print(quote)

# 5. Place a market order (USE WITH CAUTION; commented out by default)
# order_result <- avanza_order(
#   session      = session,
#   account_id   = account_id,
#   order_book_id = "199694",
#   type         = "BUY",
#   price        = NULL,
#   volume       = 1,
#   valid_until  = NULL
# )
# print(order_result)
