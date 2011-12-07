module Shoehorn
  class Receipts < DocumentsBase

    def initialize(connection)
      @connection = connection
      initialize_options
      receipts, self.matched_count = get_receipts
      super(receipts || [])
    end

    def self.parse(xml)
      receipts = Array.new
      document = REXML::Document.new(xml)
      matched_count = document.elements["GetReceiptCallResponse"].elements["Receipts"].attributes["count"].to_i rescue 1
      document.elements.collect("//Receipt") do |receipt_element|
        begin
          receipt = Receipt.new
          receipt.id = receipt_element.attributes["id"]
          receipt.store = receipt_element.attributes["store"]
          receipt.total = receipt_element.attributes["total"]
          receipt.document_currency = receipt_element.attributes["documentCurrency"]
          receipt.account_currency = receipt_element.attributes["accountCurrency"]
          receipt.conversion_rate = receipt_element.attributes["conversionRate"]
          receipt.document_total = receipt_element.attributes["documentTotal"]
          receipt.converted_total = receipt_element.attributes["convertedTotal"]
          receipt.formatted_document_total = receipt_element.attributes["formattedDocumentTotal"]
          receipt.formatted_converted_total = receipt_element.attributes["formattedConvertedTotal"]
          receipt.document_tax = receipt_element.attributes["documentTax"]
          receipt.converted_tax = receipt_element.attributes["convertedTax"]
          receipt.formatted_document_tax = receipt_element.attributes["formattedDocumentTax"]
          receipt.formatted_converted_tax = receipt_element.attributes["formattedConvertedTax"]
          receipt.modified_date = receipt_element.attributes["modifiedDate"]
          receipt.created_date = receipt_element.attributes["createdDate"]
          receipt.selldate = receipt_element.attributes["selldate"]

          category_element = receipt_element.elements["Categories"]
          receipt.categories = category_element ? Categories.parse(category_element.to_s) : []

          image_element = receipt_element.elements["Images"]
          receipt.images = image_element ? Images.parse(image_element.to_s) : []
        rescue => e
          raise Shoehorn::ParseError.new(e, receipt_element.to_s, "Error parsing receipt.")
        end
        receipts << receipt
      end
      return receipts, matched_count
    end

    def find_by_id(id)
      request = build_single_receipt_request(id)
      response = connection.post_xml(request)

      receipts, matched_count = Receipts.parse(response)
      receipts.empty? ? nil : receipts[0]
    end

private
    def get_receipts
      request = build_receipt_request
      response = connection.post_xml(request)

      Receipts.parse(response)
    end

    def build_receipt_request(options={})
      process_options(options)

      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml.Request(:xmlns => "urn:sbx:apis:SbxBaseComponents") do |xml|
        connection.requester_credentials_block(xml)
        xml.GetReceiptCall do |xml|
          xml.ReceiptFilter do |xml|
            xml.Results(per_page)
            xml.PageNo(current_page)
            xml.Category(category_id) if category_id
            xml.ModifiedSince(modified_since) if modified_since
          end
        end
      end

    end

    def build_single_receipt_request(id)
      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml.Request(:xmlns => "urn:sbx:apis:SbxBaseComponents") do |xml|
        connection.requester_credentials_block(xml)
        xml.GetReceiptInfoCall do |xml|
          xml.ReceiptFilter do |xml|
            xml.ReceiptId(id)
          end
        end
      end
    end
    
  end
end