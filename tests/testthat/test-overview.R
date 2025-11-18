test_that("avanza_overview returns tibble with expected columns", {
  skip_if_not_installed("httptest2")
  skip_on_cran()
  library(httptest2)

  fake_accounts <- list(
    list(
      accountId = "12345678",
      name = "Main Account",
      totalValue = 1200000,
      buyingPower = 50000,
      positions = list(list(id = 1), list(id = 2)),
      instruments = 12,
      unrealizedPnl = 15000
    ),
    list(
      accountId = "87654321",
      name = "Savings",
      totalValue = 340000,
      buyingPower = 100000,
      positions = list(list(id = 1)),
      instruments = 5,
      unrealizedPnl = 2100
    )
  )

  httptest2::with_mocked_bindings(
    list(avanza_request = function(session, method, path, query = NULL, body = NULL) {
      expect_equal(method, "GET")
      expect_true(grepl("customer/accounts", path))
      list(accounts = fake_accounts)
    }),
    {
      session <- avanza_session(username = "u", password = "p", totp_secret = "")
      out <- avanza_overview(session)
      expect_true(tibble::is_tibble(out))
      expect_true(all(c("account_id", "name", "total_value", "buying_power", "positions", "instruments", "unrealized_pnl") %in% names(out)))
      expect_equal(nrow(out), 2)
      expect_type(out$total_value, "double")
      expect_type(out$buying_power, "double")
      expect_type(out$positions, "integer")
    }
  )
})
