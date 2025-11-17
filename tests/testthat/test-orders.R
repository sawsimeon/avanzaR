test_that("avanza_order returns order id and status for market and limit orders", {
  skip_if_not_installed("httptest2")
  skip_on_cran()
  library(httptest2)

  httptest2::with_mocked_bindings(
    list(avanza_request = function(session, method, path, query = NULL, body = NULL) {
      expect_equal(method, "POST")
      expect_true(grepl("order", path))
      # Simulate different responses for market vs limit orders
      if (!is.null(body$orderType) && body$orderType == "MARKET") {
        list(orderId = "a1b2c3d4-e5f6-7890", status = "PLACED")
      } else {
        list(orderId = "z9y8x7w6-v5u4-3210", status = "PLACED")
      }
    }),
    {
      session <- avanza_session(username = "u", password = "p", totp_secret = "")
      # Market order
      res_market <- avanza_order(session = session, account_id = "12345678", order_book_id = "199694", type = "BUY", price = NULL, volume = 10)
      expect_type(res_market$orderId, "character")
      expect_equal(res_market$status, "PLACED")

      # Limit order
      res_limit <- avanza_order(session = session, account_id = "12345678", order_book_id = "199694", type = "SELL", price = 100.5, volume = 5, valid_until = "2025-12-31")
      expect_type(res_limit$orderId, "character")
      expect_equal(res_limit$status, "PLACED")
    }
  )
})
