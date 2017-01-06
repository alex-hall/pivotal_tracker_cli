require 'spec_helper'
require 'byebug'

describe PivotalTrackerCli::Client do
  context 'Pivotal Tracker API Endpoints Integration' do

    let(:api_token) { 'SECRET API TOKEN' }
    let(:project_id) { 'PROJECT ID' }
    let(:username) { 'USERNAME' }

    before do
      allow(YAML)
          .to receive(:load_file)
                  .and_return({
                                  'api_token' => api_token,
                                  'project_id' => project_id,
                                  'username' => username
                              })

      allow(PivotalTrackerCli::Api)
          .to receive(:get_all_users_for_project)
                  .with(project_id, api_token)
                  .and_return({
                                  'TEST_TEST' => 123456,
                                  'OTHER_TEST' => 444444
                              })

      allow(ENV).to receive(:[]).with(anything).and_call_original
      allow(ENV).to receive(:[]).with('HOME').and_return('HOME_PATH')

      allow(File).to receive(:open).with('HOME_PATH/.pt', 'w').and_return({ })
    end


    subject {
      PivotalTrackerCli::Client.new([], {}, {})
    }

    describe 'initialize' do
      context 'when the user cache is empty' do
        it 'attempts to pull down and cache all users' do
          expect(subject.username_to_user_id_map)
              .to eq({
                         'TEST_TEST' => 123456,
                         'OTHER_TEST' => 444444
                     })
        end
      end
    end


    describe '#find_current_stories' do
      context 'when fetching all of a users stories' do
        context 'when all parameters are valid' do
          before do
            allow(PivotalTrackerCli::Api)
                .to receive(:get_current_stories_for_user)
                        .with(project_id, api_token, username)
                        .and_return([{
                                         story_id: 1111111,
                                         story_name: '**THIS** IS THE FIRST STORY',
                                         status: 'accepted'
                                     }, {
                                         story_id: 2222222,
                                         story_name: '**THIS** IS THE SECOND STORY',
                                         status: 'rejected'
                                     }])
          end

          it 'print a friendly list of stories' do
            output =
                <<~TEXT
                  ****************************************
                  Story ID: 1111111
                  Story Name: **THIS** IS THE FIRST STORY
                  Status: accepted
                  ****************************************
                  Story ID: 2222222
                  Story Name: **THIS** IS THE SECOND STORY
                  Status: rejected
                  ****************************************
            TEXT
            expect {
              subject.find_current_stories
            }.to output(output).to_stdout
          end
        end

        context 'when something goes wrong' do
          before do
            allow(PivotalTrackerCli::Api)
                .to receive(:get_current_stories_for_user)
                        .and_return([{
                                         error: 'SOME VERY BAD ERROR',
                                     }])
          end

          it 'prints the error message' do
            output =
                <<~TEXT
                  ****************************************
                  Error: SOME VERY BAD ERROR
                  ****************************************
            TEXT
            expect {
              subject.find_current_stories
            }.to output(output).to_stdout
          end

        end
      end
    end

    context 'when manipulating story states' do
      let(:id) { 'SOME ID' }

      before do
        allow(PivotalTrackerCli::Api)
            .to receive(:update_story_state)
                    .with(project_id, api_token, id, updated_state)
                    .and_return("Story ##{id} successfully #{updated_state}.")
      end

      context 'when starting a story' do
        let(:updated_state) { 'started' }

        context 'and the story id exists' do
          it 'should updated the status to started' do

            expect {
              subject.start(id)
            }.to output("Story ##{id} successfully started.\n").to_stdout

          end
        end
      end

      context 'when unstarting a story' do
        let(:updated_state) { 'unstarted' }

        it 'should update the status to unstarted' do
          expect {
            subject.unstart(id)
          }.to output("Story ##{id} successfully unstarted.\n").to_stdout
        end
      end

      context 'when delivering the story' do
        let(:updated_state) { 'delivered' }

        it 'should deliver the story' do
          expect {
            subject.deliver(id)
          }.to output("Story ##{id} successfully delivered.\n").to_stdout
        end
      end

      context 'when finishing the story' do
        before do
          allow(PivotalTrackerCli::Api)
              .to receive(:get_story_by_id)
                      .with(project_id, api_token, id).and_return({type: 'story'})
        end

        let(:updated_state) { 'finished' }

        it 'should finish the story' do
          expect {
            subject.finish(id)
          }.to output("Story ##{id} successfully finished.\n").to_stdout
        end
      end
    end

    context 'when manipulating chore states' do
      let(:id) { 'SOME ID' }


      context 'when closing a chore' do
        before do
          allow(PivotalTrackerCli::Api)
              .to receive(:update_story_state)
                      .with(project_id, api_token, id, updated_state)
                      .and_return("Story ##{id} successfully #{updated_state}.")

          allow(PivotalTrackerCli::Api)
              .to receive(:get_story_by_id)
                      .with(project_id, api_token, id).and_return({type: 'chore'})
        end

        let(:updated_state) { 'accepted' }

        it 'should close a chore' do
          expect {
            subject.finish(id)
          }.to output("Story ##{id} successfully accepted.\n").to_stdout
        end
      end
    end
  end
end
