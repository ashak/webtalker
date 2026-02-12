class MessagesController < ApplicationController
  # GET /messages/new
  def new
    @message = Message.new
  end

  # POST /messages or /messages.json
  def create
    @message = Message.new(message_params)
    @message.sender = Current.user

    respond_to do |format|
      if @message.save
        format.turbo_stream
        format.html { redirect_to @message, notice: "Message was successfully created." }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  private
    # Only allow a list of trusted parameters through.
    def message_params
      params.expect(message: [ :content ])
    end
end
