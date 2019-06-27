0.3.0 2019-06-27
==========================================================

- Fixes issues with not saving a file content_type as well as bad calls for the fog methods (Thanks @dan)
- method name typo: josn_response?->json_response? (Thanks @MatthiasWinkelmann)
- Change Fog::Storage::Backblaze -> Fog::Backblaze::Storage

0.2.0 2018-08-16
==========================================================

- Add support for api keys
- More tests
- Add CHANGELOG.md

0.1.2 2018-05-19
==========================================================

- Support IO objects for #put_object
- Support `options[:extra_headers]` for #put_object
- Use autoload
- Add #update_bucket
- Always use `::JSON`

0.1.1 2018-03-25
==========================================================

- Basic functionality
