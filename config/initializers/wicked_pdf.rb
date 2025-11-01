WickedPdf.config ||= {
  exe_path: (ENV['WKHTMLTOPDF_PATH'].presence || WickedPdf.binary),
  layout:   'pdf'
}
