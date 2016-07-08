require "spec_helper"

RSpec.describe Timeout do
  describe ".backend" do
    let(:handler) { double(:handler) }
    it "allows to switch timeout backends on the fly" do
      within_thread do
        expect(Thread.current.timeout_handler).to be_nil
        Timeout.backend(handler) do
          expect(Thread.current.timeout_handler).to be(handler)
          expect(handler).to receive(:call).with(2)
          Timeout.timeout(2) {}
        end
        expect(Thread.current.timeout_handler).to be_nil
      end
    end
  end
end
