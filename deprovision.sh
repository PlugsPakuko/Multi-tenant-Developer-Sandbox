# Usage: ./deprovision.sh <student-id>
# Example: ./deprovision.sh 06

set -e

STUDENT_ID=$1

if [ -z "$STUDENT_ID" ]; then
  echo "Usage: ./deprovision.sh <student-id>"
  exit 1
fi

echo ">>> Removing sandbox for student-${STUDENT_ID}..."

# Remove from values.yaml
sed -i "/  - id: \"${STUDENT_ID}\"/d" helm/values.yaml
echo "    Removed student-${STUDENT_ID} from values.yaml"

# Delete the namespace
kubectl delete namespace student-${STUDENT_ID} --ignore-not-found
echo "    Namespace deleted"

# Upgrade helm to sync state
helm upgrade sandbox ./helm

echo ""
echo "Done! student-${STUDENT_ID} has been removed."