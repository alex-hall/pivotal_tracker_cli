require 'spec_helper'
require_relative '../lib/api'

describe PivotalTrackerCli::Api do


  describe '#get_all_users_for_project' do
    context 'when retrieving users for the project' do
      let(:membership_response) do
        [
            {
                'kind' => 'project_membership',
                'id' => 'SOME ID',
                'created_at' => '2015-09-18T17:56:20Z',
                'updated_at' => '2017-01-05T14:10:31Z',
                'person' => {
                    'kind' => 'robot',
                    'id' => 123456,
                    'name' => 'TEST R. TESTER',
                    'email' => 'test_r_tester@test.biz',
                    'initials' => 'TT',
                    'username' => 'TEST_TEST'
                },
                'project_id' => 'SOME PROJECT ID',
                'role' => 'owner',
            }, {
                'kind' => 'project_membership',
                'id' => 'SOME OTHER ID',
                'created_at' => '2015-09-18T17:56:20Z',
                'updated_at' => '2017-01-05T14:10:31Z',
                'person' => {
                    'kind' => 'robot',
                    'id' => 444444,
                    'name' => 'OTHER R. TESTER',
                    'email' => 'other_r_tester@test.biz',
                    'initials' => 'OT',
                    'username' => 'OTHER_TEST'
                },
                'project_id' => 'SOME PROJECT ID',
                'role' => 'owner',
            },
        ]
      end

      before do
        allow(HTTParty)
            .to receive(:get)
                    .with('https://www.pivotaltracker.com/services/v5/projects/SOME PROJECT ID/memberships',
                          headers: {
                              'X-TrackerToken': 'SOME API TOKEN'
                          })
                    .and_return(double(:response, success?: true, parsed_response: membership_response))
      end

      it 'should return a key value pair of username and user id' do
        user_hash =
            {
                'TEST_TEST' => 123456,
                'OTHER_TEST' => 444444
            }
        expect(PivotalTrackerCli::Api.get_all_users_for_project('SOME PROJECT ID', 'SOME API TOKEN')).to eq(user_hash)
      end
    end
  end

  describe '#get_current_stories_for_user' do
    context 'when the service call is successful' do
      let(:story_response) do
        double(:response, parsed_response: {
            'kind' => 'story',
            'id' => 4321000,
            'created_at' => '2017-01-03T18:39:31Z',
            'updated_at' => '2017-01-03T20:25:14Z',
            'estimate' => 0,
            'story_type' => 'feature',
            'name' => 'DUMMY: STORY FEATURE TESTING PURPOSES',
            'description' => 'Used to test pivotal tracker cli.',
            'current_state' => 'finished',
            'requested_by_id' => 444444,
            'url' => 'https://www.pivotaltracker.com/story/show/4321000',
            'project_id' => 123456,
            'owner_ids' => [],
            'labels' => []
        })
      end

      before do
        allow(HTTParty)
            .to receive(:get)
                    .with('https://www.pivotaltracker.com/services/v5/projects/PROJECT_ID/search', {
                        query: {
                            query: 'owner:"USERNAME"'
                        },
                        headers: {
                            'X-TrackerToken': 'SOME API TOKEN'
                        }
                    }).and_return(double(:response, success?: true, parsed_response: parsed_story_list_response))
      end

      it 'returns a list of stories' do
        stories = PivotalTrackerCli::Api.get_current_stories_for_user('PROJECT_ID', 'SOME API TOKEN', 'USERNAME')
        expect(stories[0][:story_id]).to eq(838383838)
        expect(stories[0][:story_name]).to eq('**THIS** IS THE FIRST STORY')
        expect(stories[0][:status]).to eq('accepted')
        expect(stories[1][:story_id]).to eq(484848484)
        expect(stories[1][:story_name]).to eq('**THIS** IS THE SECOND STORY')
        expect(stories[1][:status]).to eq('rejected')
      end
    end

    context 'when the service call returns an error' do
      before do
        allow(HTTParty)
            .to receive(:get)
                    .and_return(double(:response, success?: false, parsed_response: {'error' => 'SOME BAD ERROR'}))
      end

      it 'returns a list containing the error' do
        stories = PivotalTrackerCli::Api.get_current_stories_for_user('PROJECT_ID', 'SOME API TOKEN', 'USERNAME')
        expect(stories[0][:error]).to eq('SOME BAD ERROR')
      end
    end

  end

  describe '#update_story_state' do
    context 'when manipulating story states' do
      let(:parsed_story_update_response) do
        {
            'kind' => 'story',
            'id' => 4321000,
            'project_id' => 123456,
            'name' => 'DUMMY: STORY FOR TESTING',
            'description' => 'ARGH! THERE BE DRAGONS!',
            'story_type' => 'chore',
            'current_state' => updated_state,
            'accepted_at' => '2017-01-04T18:46:24Z',
            'requested_by_id' => 444444,
            'owner_ids' => [],
            'labels' => [],
            'created_at' => '2017-01-03T15:40:00Z',
            'updated_at' => '2017-01-04T18:46:25Z',
            'url' => 'https://www.pivotaltracker.com/story/show/136951207'
        }
      end

      let(:failed_story_update_response) do
        {
            'code' => 'invalid_parameter',
            'kind' => 'error',
            'error' => 'One or more request parameters was missing or invalid.',
            'requirement' => 'The id parameter value was "BANANA" but must be of type int'
        }
      end

      before do
        allow(HTTParty)
            .to receive(:put)
                    .with('https://www.pivotaltracker.com/services/v5/projects/PROJECT_ID/stories/4321000',
                          headers: {
                              'X-TrackerToken': 'SOME API TOKEN'
                          },
                          body: {
                              'current_state': updated_state
                          }
                    ).and_return(double(:response, success?: true, parsed_response: parsed_story_update_response))
      end

      context 'when changing a story state' do
        let(:updated_state) { 'started' }


        context 'and the story id exists' do
          it 'should updated the status' do
            expect(PivotalTrackerCli::Api.update_story_state('PROJECT_ID', 'SOME API TOKEN', 4321000, updated_state))
                .to eq('Story #4321000 successfully started.')
          end
        end
      end
    end
  end

  describe '#get_story_by_id' do
    before do
      allow(HTTParty)
          .to receive(:get)
                  .with('https://www.pivotaltracker.com/services/v5/projects/PROJECT_ID/stories/SOME_STORY_ID',
                        headers: {
                            'X-TrackerToken': 'SOME API TOKEN'
                        })
                  .and_return(story_response)
    end

    let(:get_story_by_id) { PivotalTrackerCli::Api.get_story_by_id('PROJECT_ID', 'SOME API TOKEN', 'SOME_STORY_ID') }

    context 'when the story exists' do
      let(:story_response) do
        double(:response, success?: true, parsed_response:
            {
                'kind' => 'story',
                'id' => 4321000,
                'created_at' => '2017-01-03T18:39:31Z',
                'updated_at' => '2017-01-03T20:25:14Z',
                'estimate' => 0,
                'story_type' => 'feature',
                'name' => 'DUMMY: STORY FEATURE TESTING PURPOSES',
                'description' => 'Used to test pivotal tracker cli.',
                'current_state' => 'finished',
                'requested_by_id' => 444444,
                'url' => 'https://www.pivotaltracker.com/story/show/4321000',
                'project_id' => 123456,
                'owner_ids' => [],
                'labels' => []
            })
      end

      it 'should return the story details' do
        expect(get_story_by_id[:type]).to eq('feature')
      end
    end

    context 'when the story does not exist' do
      let(:story_response) do
        double(:response, success?: false, parsed_response:
            {
                'code' => 'invalid_parameter',
                'kind' => 'error',
                'error' => 'One or more request parameters was missing or invalid.',
                'requirement' => 'The id parameter value was "BANANA" but must be of type int'
            })
      end

      it 'should return an error' do
        expect(get_story_by_id[:error]).to eq('One or more request parameters was missing or invalid.')
      end
    end
  end

  let(:parsed_story_list_response) do
    {
        'stories' => {
            'stories' => [
                {

                    'kind' => 'story',
                    'id' => 838383838,
                    'created_at' => '2016-02-23T20:47:49Z',
                    'updated_at' => '2016-12-30T14:44:37Z',
                    'accepted_at' => '2016-12-30T12:29:23Z',
                    'estimate' => 0,
                    'story_type' => 'feature',
                    'name' => '**THIS** IS THE FIRST STORY',
                    'description' => 'SOME VERY LONG DESCRIPTION',
                    'current_state' => 'accepted',
                    'requested_by_id' => 222222,
                    'url' => 'https://www.pivotaltracker.com/story/show/838383838',
                    'project_id' => 123456,
                    'owner_ids' => [333333],
                    'labels' => [
                        {
                            'id' => 11111,
                            'project_id' => 123456,
                            'kind' => 'label',
                            'name' => 'SOME LABEL',
                            'created_at' => '2016-12-02T15:50:23Z',
                            'updated_at' => '2016-12-02T15:50:23Z'
                        }
                    ],
                    'owned_by_id' => 333333
                }, {
                    'kind' => 'story',
                    'id' => 484848484,
                    'created_at' => '2016-12-01T22:03:22Z',
                    'updated_at' => '2016-12-30T13:17:33Z',
                    'estimate' => 2,
                    'story_type' => 'feature',
                    'name' => '**THIS** IS THE SECOND STORY',
                    'description' => 'SOME VERY LONG DESCRIPTION',
                    'current_state' => 'rejected',
                    'requested_by_id' => 1824512,
                    'url' => 'https://www.pivotaltracker.com/story/show/484848484',
                    'project_id' => 123456,
                    'owner_ids' => [333333, 444444],
                    'labels' => [
                        {
                            'id' => 17161133,
                            'project_id' => 123456,
                            'kind' => 'label',
                            'name' => 'PLANNING',
                            'created_at' => '2016-12-09T15:11:51Z',
                            'updated_at' => '2016-12-09T15:11:51Z'
                        }
                    ],
                    'owned_by_id' => 333333
                }],
            'total_points' => 2,
            'total_points_completed' => 0,
            'total_hits' => 2,
            'total_hits_with_done' => 48
        },
        'query' => ''
    }
  end

end
