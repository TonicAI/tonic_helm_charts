## Tonic Helm Chart ##

### Tonic Overview
**Production** - https://tonic.eq-prod.fool.com/

You can access Tonic Production via Okta.

**Staging** - https://tonic-staging.eq-staging.fool.com/

Staging is ONLY used to test upgrades. You can log in using the credentials below. It is using a RDS in AWS-Lab as the source DB.
### How-to update

Updating Tonic is intentionally a manual process, we do this for scm reasons. It can be up updated and deployed to Staging or Production using a Jenkins Job.

!! Take a backup on the tonic_ai DB before upgrading !!

1. Clone this repo.
2. Update `version.env` to the desired version to deploy.
3. Merge to master.
4. Go to the [tonic-deploy](https://leroy.foolhq.com/job/Utilities/job/tonic/job/tonic-deploy/) jenkins job.
5. Click `Build with Parameters` and choose which environment you would like to deploy to.

Thats it!

### How to rollback to a previous revision

1. Check revisions and choose which revision to rollback to.

`helm history tonic -n tonic`

2. Rollback to desired version. You can run `--dry-run first` and remove the flag if there are no issues.

`helm rollback tonic <version> -n tonic --dry-run`


### Important Links
Tonic Prod secrets - [tonic-prod secrets](https://tpm.foolhq.com/index.php/pwd/view/2974). This is the original non-redacted values.yaml for production.

Tonic-staging Admin account - [tonic-staging admin credentials](https://tpm.foolhq.com/index.php/pwd/view/3236)

Tonic DB and Workspace backups - [tonic backups](https://drive.google.com/drive/folders/1oyafeGTe0IQuyAWlu_AzE0KNST9nJAbx?usp=sharing)