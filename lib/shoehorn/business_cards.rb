require 'rexml/document'
require 'builder'

module Shoehorn
  class BusinessCards  < Array
    
    attr_accessor :connection, :matched_count

    def initialize(connection)
      @connection = connection
      business_cards, @matched_count = get_business_cards
      super(business_cards || [])
    end

    def refresh
      initialize(@connection)
    end

    def self.parse(xml)
      business_cards = Array.new
      document = REXML::Document.new(xml)
      matched_count = document.elements["GetBusinessCardCallResponse"].elements["BusinessCards"].attributes["count"].to_i rescue 1
      document.elements.collect("//BusinessCard") do |business_card_element|
        begin
          business_card = BusinessCard.new
          business_card.id = business_card_element.attributes["id"]
          business_card.first_name = business_card_element.attributes["firstName"]
          business_card.last_name = business_card_element.attributes["lastName"]
          business_card.create_date = business_card_element.attributes["createDate"]
          business_card.address = business_card_element.attributes["address"]
          business_card.address2 = business_card_element.attributes["address2"]
          business_card.city = business_card_element.attributes["city"]
          business_card.state = business_card_element.attributes["state"]
          business_card.zip = business_card_element.attributes["zip"]
          business_card.country = business_card_element.attributes["country"]
          business_card.email = business_card_element.attributes["email"]
          business_card.website = business_card_element.attributes["website"]
          business_card.company = business_card_element.attributes["company"]
          business_card.position = business_card_element.attributes["position"]
          business_card.work_phone = business_card_element.attributes["workPhone"]
          business_card.cell_phone = business_card_element.attributes["cellPhone"]
          business_card.fax = business_card_element.attributes["fax"]
          business_card.front_img_url = business_card_element.attributes["frontImgUrl"]
          business_card.back_img_url = business_card_element.attributes["backImgUrl"]
          business_card.note = business_card_element.attributes["note"]
        rescue => e
          raise Shoehorn::ParseError.new(e, receipt_element.to_s, "Error parsing receipt.")
        end
        business_cards << business_card
      end
      return business_cards, matched_count
    end

    def find_by_id(id)
      request = build_single_business_card_request(id)
      response = connection.post_xml(request)

      business_cards, matched_count = BusinessCards.parse(response)
      business_cards.empty? ? nil : business_cards[0]
    end

private
    def get_business_cards
      request = build_business_card_request
      response = connection.post_xml(request)

      BusinessCards.parse(response)
    end

    def build_business_card_request(options={})
      results = options[:per_page] || 50
      page_no = options[:page] || 1
      modified_since = options[:modified_since]

      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml.Request(:xmlns => "urn:sbx:apis:SbxBaseComponents") do |xml|
        connection.requester_credentials_block(xml)
        xml.GetBusinessCardCall do |xml|
          xml.BusinessCardFilter do |xml|
            xml.Results(results)
            xml.PageNo(page_no)
            xml.ModifiedSince(modified_since) if modified_since
          end
        end
      end
    end


    def build_single_business_card_request(id)
      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml.Request(:xmlns => "urn:sbx:apis:SbxBaseComponents") do |xml|
        connection.requester_credentials_block(xml)
        xml.GetBusinessCardInfoCall do |xml|
          xml.BusinessCardFilter do |xml|
            xml.BusinessCardId(id)
          end
        end
      end
    end

  end
end