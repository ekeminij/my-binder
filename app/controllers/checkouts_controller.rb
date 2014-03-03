class CheckoutsController < ApplicationController
  # permissions error - when enabled, this tries to find a Checkout with the current related model id on creation
  # load_and_authorize_resource

  # GET /checkouts
  # GET /checkouts.json
  def index
    @checkouts = Checkout.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @checkouts }
    end
  end

  #declare error classes
  class ToolAlreadyCheckedIn < Exception
  end

  class ToolAlreadyCheckedOut < Exception
  end

  class ToolDoesNotExist < Exception
  end

  class ParticipantDoesNotExist < Exception
  end

  class OrganizationDoesNotExist < Exception
  end

  # GET /checkouts/new
  # GET /checkouts/new.json
  def new
    @checkout = Checkout.new
    @tool = Tool.find_by_id(params[:tool_id])
    
    raise ToolDoesNotExist unless !@tool.blank?
    
    @checkout.tool = @tool

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @checkout }
    end
  end

  # POST /checkouts
  # POST /checkouts.json
  def create
    @checkout = Checkout.new

    @tool = Tool.find(params[:tool_id])
    raise ToolDoesNotExist unless !@tool.nil?

    raise ToolAlreadyCheckedOut unless not @tool.is_checked_out?

    unless params[:checkout].blank?
      @participant = Participant.find_by_card(params[:checkout][:card_number].to_s) #this creates a CMU directory request to get the andrew id associated with the card number. Then finds the local DB mapping to get the participant id.
    
      @participant = Participant.find_by_andrewid(params[:checkout][:card_number]) unless !@participant.nil?

      raise ParticipantDoesNotExist unless !@participant.nil?
    else
      @participant = Participant.find(params[:participant_id])
      
      @organization = Organization.find(params[:organization_id])
      raise OrganizationDoesNotExist unless !@organization.nil?
    end


    if @organization.blank? and @participant.organizations.size != 1
      respond_to do |format|
        format.html { render "choose_organization", :tool => @tool, :participant => @participant }
        format.json { render json: @checkouts }
      end
    else
      @checkout.checked_out_at = Time.now
      @checkout.tool_id = @tool.id
      @checkout.participant_id = @participant.id
      @checkout.organization_id = @participant.organizations.first.id unless @participant.organizations.nil? or @participant.organizations.first.nil?

      respond_to do |format|
        if @checkout.save
          format.html { redirect_to @checkout.tool, notice: 'Checkout was successfully created.' }
          format.json { render json: @checkout, status: :created, location: @checkout }
        else
          format.html { render action: "new" }
          format.json { render json: @checkout.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PUT /checkouts/1
  # PUT /checkouts/1.json
  def update
    @checkout = Checkout.find(params[:id])
    @checkout.checked_in_at = Time.now

    respond_to do |format|
      if @checkout.save
        format.html { redirect_to params[:url], notice: 'Checkout was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @checkout.errors, status: :unprocessable_entity }
      end
    end
  end
end

