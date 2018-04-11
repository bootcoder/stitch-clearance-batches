module CapybaraHelper

  include Capybara::DSL

  def pdf_to_pdf
    temp_pdf = Tempfile.new('pdf')
    temp_pdf << page.source.force_encoding('UTF-8')
    reader = PDF::Reader.new(temp_pdf)
    pdf_text = reader.pages.map(&:text)
    temp_pdf.close
    page.driver.response.instance_variable_set('@body', pdf_text)
  end

end
