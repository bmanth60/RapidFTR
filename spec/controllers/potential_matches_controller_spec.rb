require 'spec_helper'

describe PotentialMatchesController, :type => :controller do

  before :each do
    reset_couchdb!
    FormSection.all.each { |fs| fs.destroy }
    fake_field_worker_login
    allow(SystemVariable).to receive(:find_by_name).and_return(double(:value => '0.00'))
    @child = create(:child, :name => 'John Doe', :gender => 'male')
    form = create(:form, :name => Enquiry::FORM_NAME)
    @form_section = create(:form_section, :name => 'enquiry_criteria', :form => form, :fields => [build(:text_field, :name => 'enquirer_name')])
    allow(MatchService).to receive(:search_for_matching_children).and_return(@child.id => '0.1')
    @enquiry = create(:enquiry, :enquirer_name => 'Foo Bar')
    allow(controller.current_ability).to receive(:can?).with(:update, Enquiry).and_return(true)
  end

  describe 'destroy' do
    it 'should remove child id from potential matches ' do
      expect(@enquiry.potential_matches.length).to eq 1
      delete :destroy, :enquiry_id => @enquiry.id, :id => @child.id
      @enquiry.reload
      expect(@enquiry.potential_matches.length).to eq 0
    end

    it 'should redirect to potential matches section of enquiry page after marking child as not matching' do
      delete :destroy, :enquiry_id => @enquiry.id, :id => @child.id
      expect(response).to redirect_to "/enquiries/#{@enquiry.id}#tab_potential_matches"
    end

    it 'should redirect to potential matches section of child page if specified' do
      delete :destroy, :enquiry_id => @enquiry.id, :id => @child.id, :return => :child
      expect(response).to redirect_to "/children/#{@child.id}#tab_potential_matches"
    end

    it 'should reject unauthorized users' do
      allow(controller.current_ability).to receive(:can?).with(:update, Enquiry).and_return(false)
      delete :destroy, :enquiry_id => @enquiry.id, :id => @child.id
      expect(response).to_not be_ok
    end
  end

  describe 'update' do
    it 'should confirm a potential match' do
      expect(PotentialMatch.first).to_not be_confirmed
      params =  {:id => @child.id, :enquiry_id => @enquiry.id, :confirmed => true}
      put :update, params

      expect(PotentialMatch.first).to be_confirmed
    end

    it 'should redirect to potential matches section of enquiry page' do
      params =  {:id => @child.id, :enquiry_id => @enquiry.id, :confirmed => true}
      put :update, params

      expect(response).to redirect_to "/enquiries/#{@enquiry.id}#tab_potential_matches"
    end

    it 'should redirect to potential matches section of child page if specificed' do
      params =  {:id => @child.id, :enquiry_id => @enquiry.id, :confirmed => true, :return => :child}
      put :update, params

      expect(response).to redirect_to "/children/#{@child.id}#tab_potential_matches"
    end

    it 'should reject unauthorize users' do
      allow(controller.current_ability).to receive(:can?).with(:update, Enquiry).and_return(false)
      params =  {:id => @child.id, :enquiry_id => @enquiry.id, :confirmed => true}
      put :update, params
      expect(response).to_not be_ok
    end
  end
end
