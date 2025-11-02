# avanzaR <a href="https://github.com/sawsimeon/avanzaR"><img src="https://img.shields.io/github/stars/sawsimeon/avanzaR?style=social" align="right" /></a>

**An unofficial R client for the Avanza API** – fetch account data, place orders, and retrieve performance reports from Sweden’s leading online broker.

> **Warning: This is an *unofficial* wrapper.** Avanza does **not** provide a public API, and the endpoints can change without notice. Use at your own risk and **never** in production without monitoring.

[![R-CMD-check](https://github.com/sawsimeon/avanzaR/workflows/R-CMD-check/badge.svg)](https://github.com/sawsimeon/avanzaR/actions)
[![CRAN status](https://www.r-pkg.org/badges/version-last-release/avanzaR)](https://CRAN.R-project.org/package=avanzaR)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Installation

```r
# Install from GitHub
remotes::install_github("sawsimeon/avanzaR")
```
Dependencies - 'httr', 'jsonlite', 'totp', 'lubridate', 'dplyr' (all installed automatically).

## Quick Start

```r
library(avanzaR)
library(totp)   # for two-factor authentication

# 1. Authenticate -------------------------------------------------
session <- avanza_auth(
  username   = "my_user",
  password   = "my_password",
  totp_secret = "JBSWY3DPEHPK3PXP"   # copy from Avanza's 2FA settings
)

# 2. Portfolio overview -------------------------------------------
overview <- avanza_overview(session)
overview
#> # A tibble: 3 × 8
#>   account_id name        total_value buying_power positions instruments unrealized_pnl
#>   <chr>      <chr>             <dbl>        <dbl>     <int>       <int>          <dbl>
#> 1 12345678   Main Account     1.2e6        5.0e4        12          12          1.5e4
#> 2 87654321   Savings          3.4e5        1.0e5         5           5          2.1e3
#> 3 11223344   ISA              8.9e5        2.0e5         8           8          3.7e4

# 3. Weekly performance report ------------------------------------
report <- avanza_insights(session, account_id = "12345678", period = "one_week")
report
#> # A tibble: 1 × 6
#>   period     roi_pct trades win_rate_pct total_pnl   avg_trade
#>   <chr>        <dbl>  <int>        <dbl>     <dbl>      <dbl>
#> 1 2025-W44      2.31      7         71.4     2780.       397.

# 4. Place a market order (use with extreme caution!) ------------
order_result <- avanza_order(
  session      = session,
  account_id   = "12345678",
  order_book_id = "199694",      # e.g. SE0000000000
  type         = "BUY",
  price        = NULL,           # NULL → market order
  volume       = 10,
  valid_until  = NULL            # today only
)

order_result
#> $orderId
#> [1] "a1b2c3d4-e5f6-7890-g1h2-i3j4k5l6m7n8"
#>
#> $status
#> [1] "PLACED"

```

## Core Functions

|Function           |Description                                                            |
|-------------------|-----------------------------------------------------------------------|
|avanza_auth()      |Log in (username + password + TOTP) and return a session object        |
|avanza_overview()  |Account balances, positions, and buying power                          |
|avanza_insights()  |Weekly / monthly performance reports.                                  |
|avanza_order()     |Place buy/sell orders (market or limit).                               |
|avanza_quote()     |Real-time price for single strument (polling).                         |
|avanza_positions() |Detailed list of holdings.                                             |

All function return tidy data frames (tibble) for seamless integration with teh tidyverse.

## Real-time Data (optional)

```r
# Simple polling example
quote <- avanza_quote(session, id = "199694")
quote
#> # A tibble: 1 × 9
#>   last_price change_pct bid ask volume market_maker highest lowest
#>        <dbl>      <dbl> <dbl> <dbl>  <int> <chr>            <dbl>  <dbl>
#> 1      132.       1.45 131.5 132.5  45231 Avanza           134.   130.
```

For true WebSocket streaming, see vignette("realtime").

## Documentation

```r
vignette("avanzaR-intro")
vignette("realtime")
?avenza_auth
```
Full reference: https://sawsimeon.github.io/avanzaR/

## Development 

```r
# Clone & install in dev mode
git clone https://github.com/sawsimeon/avanzaR.git
Rscript -e 'devtools::install("avanzaR", build_vignettes = TRUE)'
```
## Disclaimer

Not affilliated with Avanza AB.
The API may break at any time.
Never store credentials in source code. Use environment variables:

```r
Sys.setenv(AVANZA_USER = "my_user")
Sys.setenv(AVANZA_PASS = "my_password")
Sys.setenv(AVANZA_TOTP = "JBSWY3DPEHPK3PXP")
session <- avanza_auth()
```
