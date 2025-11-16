test_that("avanza_auth stores session cookie on success", {
  skip_if_not_installed("httptest2")
  skip_on_cran()
  library(httptest2)

  fake_resp <- list(sessionId = "fake-session-1234")

  httptest2::with_mocked_bindings(
    list(avanza_request = function(session, method, path, query = NULL, body = NULL) {
      expect_equal(method, "POST")
      expect_true(grepl("auth", path))
      fake_resp
    }),
    {
      session <- avanza_session(username = "u", password = "p", totp_secret = "")
      out <- avanza_auth(username = "u", password = "p", totp_secret = "")
      expect_s3_class(out, "AvanzaSession")
      expect_true(!is.null(out$cookies$sessionId))
      expect_equal(out$cookies$sessionId, "fake-session-1234")
    }
  )
})
