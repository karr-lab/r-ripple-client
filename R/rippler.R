
#' Pull Data from Ripple Science API
#'
#' @param url URL of your Ripple Instance, by default pulled from `RIPPLER_RIPPLE_URL` environment variable.
#' @param study_id Study ID to pull from, by default pulled from `RIPPLER_RIPPLE_STUDY_ID` environment variable.
#' @param variables (optional) a vector of variables to pull, by default the complete set of standard and custom variables
#' @param output_file (optional) a CSV to write data to
#'
#' @return a data frame containing the data from Ripple Science API (invisibly, if `output_file` is specified)
#' @export
#'
ripple_download <- function(
    url = Sys.getenv('RIPPLER_RIPPLE_URL'),
    study_id = Sys.getenv('RIPPLER_RIPPLE_STUDY_ID'),
    variables = c(standard_vars, custom_vars),
    output_file = NULL
  ){
  req <- httr2::request(url) |>
    httr2::req_url_path('/v1/export/') |>
  	httr2::req_auth_basic(
  		ifelse(Sys.getenv('RIPPLER_RIPPLE_USER') == '', getPass::getPass('Ripple Username', forcemask = FALSE), Sys.getenv('RIPPLER_RIPPLE_USER')),
  		ifelse(Sys.getenv('RIPPLER_RIPPLE_PASS') == '', getPass::getPass('Ripple Password'), Sys.getenv('RIPPLER_RIPPLE_PASS'))
  	) |>
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
  dat <- read.csv(text = httr2::resp_body_string(resp), stringsAsFactors = FALSE, check.names = FALSE)
  return(dat)
}

#' Push data to Ripple Science API
#'
#' @param url URL of your Ripple Instance, by default pulled from `RIPPLER_RIPPLE_URL` environment variable.
#' @param study_id Study ID to pull from, by default pulled from `RIPPLER_RIPPLE_STUDY_ID` environment variable.
#' @param dat a data frame to push to Ripple (required if `file` not set)
#' @param file an xlsx file to push to Ripple (required if `dat` is not set)
#' @param update update type. One of `'all'` (update all participants, the default),
#' `'nocontact'` (do not update any contact info), or
#' `'noexisting'`(do not update any existing participants).
#'
#' @return value returned by `httr2::req_perform` on upload
#' @export
#'
ripple_upload <- function(
		url = Sys.getenv('RIPPLER_RIPPLE_URL'),
		study_id = Sys.getenv('RIPPLER_RIPPLE_STUDY_ID'),
    dat = NULL,
    file = NULL,
    update = c('all', 'nocontact', 'noexisting') # default all
  ){
	assertthat::assert_that(xor(is.null(dat), is.null(file)), msg = 'One (and not both) of `dat`, `file` must be provided.')
  assertthat::assert_that(!is.null(dat) || assertthat::has_extension(file, '.xlsx'), msg = '`file` should be an xlsx file.')
	update <- rlang::arg_match(update)

	if(is.null(file)){ # format and write temp file if given data frame
		file <- tempfile(fileext = '.xlsx')
		dat$importType <- study_id
		writexl::write_xlsx(dat, file)
	}
  req <- httr2::request(url) |>
    httr2::req_url_path('/v1/import/') |>
  	httr2::req_auth_basic(
  		ifelse(Sys.getenv('RIPPLER_RIPPLE_USER') == '', getPass::getPass('Ripple Username', forcemask = FALSE), Sys.getenv('RIPPLER_RIPPLE_USER')),
  		ifelse(Sys.getenv('RIPPLER_RIPPLE_PASS') == '', getPass::getPass('Ripple Password'), Sys.getenv('RIPPLER_RIPPLE_PASS'))
  	) |>
  	httr2::req_method('POST') |>
    httr2::req_url_query(
      importtype = study_id,
      updateoption = update
    ) |>
    httr2::req_headers(
      `Content-Type` = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    	#`Content-Type` = 'text/csv',
      `Connection` = 'keep-alive',
      `Keep-Alive` = 'timeout=360, max=1000'
    ) |>
    httr2::req_body_file(file) |>
    httr2::req_error(body = function(resp) httr2::resp_body_string(resp)) # Include body of response in error
	tryCatch(
		{
  		httr2::req_perform(req)
		},
		finally = if(!is.null(dat)) file.remove(file) # clean up temp files
	)
}


