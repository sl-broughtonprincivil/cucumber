require 'cucumber/messages'

module Cucumber
  module Messages
    describe Messages do

      it "json-roundtrips messages" do
        a1 = Attachment.new(body: 'hello')
        expect(a1.body).to eq('hello')
        a2 = Attachment.new(JSON.parse(a1.to_json(proto3: true)))
        expect(a2).to(eq(a1))
      end

      it "omits empty string fields in output" do
        io = StringIO.new
        message = Envelope.new(source: Source.new(data: ''))
        message.write_ndjson_to(io)

        io.rewind
        json = io.read

        expect(json).to eq("{\"source\":{}}\n")
      end

      it "omits empty number fields in output" do
        io = StringIO.new
        message = Envelope.new(
          test_case_started: TestCaseStarted.new(
            timestamp: Timestamp.new(
              seconds: 0
            )
          )
        )
        message.write_ndjson_to(io)

        io.rewind
        json = io.read

        expect(json).to eq('{"testCaseStarted":{"timestamp":{}}}' + "\n")
      end

      it "omits empty repeated fields in output" do
        io = StringIO.new
        message = Envelope.new(
          parameter_type: ParameterType.new(
            regular_expressions: []
          )
        )
        message.write_ndjson_to(io)

        io.rewind
        json = io.read

        expect(json).to eq('{"parameterType":{}}' + "\n")
      end

      it "can be serialised over an ndjson stream" do
        outgoing_messages = [
          Envelope.new(source: Source.new(data: 'Feature: Hello')),
          Envelope.new(attachment: Attachment.new(binary: [1,2,3,4].pack('C*')))
        ]

        io = StringIO.new
        write_outgoing_messages(outgoing_messages, io)

        io.rewind
        incoming_messages = NdjsonToMessageEnumerator.new(io)

        expect(incoming_messages.to_a).to(eq(outgoing_messages))
      end

      def write_outgoing_messages(messages, out)
        messages.each do |message|
          message.write_ndjson_to(out)
        end
      end
    end
  end
end
