
#' Pull Data from Ripple
#'
#' @param url
#' @param study_id
#' @param variables implement me
#' @param output_file
#'
#' @return
#' @export
#'
#' @examples
ripple_download <- function(
    url = Sys.getenv('rippler.ripple_url'),
    study_id = Sys.getenv('rippler.study_id'),
    variables = standard_vars,
    output_file = NULL
  ){
  req <- httr2::request(url) |>
    httr2::req_url_path('/v1/export/') |>
    httr2::req_auth_basic(Sys.getenv('rippler.ripple_user', unset = NA), Sys.getenv('rippler.ripple_pass', unset = NA)) |>
    httr2::req_method('POST') |>
    httr2::req_body_raw(
      glue::glue(
        'export-type={study_id}',
        'export-timezone={utils::URLencode(Sys.timezone(), reserved = TRUE)}',
        glue::glue_collapse(variables, '=on&'),
        '=on',
        .sep = '&'
      ),
      'application/x-www-form-urlencoded'
    )

  resp <- httr2::req_perform(req)

  # Write to a file
  if(!is.null(output_file)){
	  httr2::resp_body_raw(resp) |>
	    writeBin(output_file)
  	return(invisible(output_file))
  }
  # Read into R
  dat <- readr::read_csv(text = httr2::resp_body_string(resp), stringsAsFactors = FALSE, check.names = FALSE)
  return(dat)
}

ripple_upload <- function(
    dat = NULL,
    file = NULL
  ){
  assertthat::assert_that(xor(is.null(dat), is.null(file)), msg = 'One (and not both) of `dat`, `file` must be provided.')
  assertthat::assert_that(!is.null(dat) || assertthat::has_extension(file, '.xlsx'), msg = '`file` should be an xlsx file.')
  req <- httr2::request(url) |>
    httr2::req_url_path('/v1/import/') |>
    httr2::req_auth_basic(Sys.getenv('rippler.ripple_user', unset = NA), Sys.getenv('rippler.ripple_pass', unset = NA)) |>
    httr2::req_method('POST') |>
    httr2::req_url_query(
      importtype = study_id,
      updateoption = 'all'
    ) |>
    httr2::req_headers(
      `Content-Type` = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      `Connection` = 'keep-alive',
      `Keep-Alive` = 'timeout=360, max=1000'
    ) |>
    httr2::req_body_file(file) |>
    httr2::req_error(body = function(resp) resp_body_string(resp)) # Include body of response in error

  httr2::req_perform(req)
}
