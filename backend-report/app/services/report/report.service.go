package report

import (
	"backend-report/app/models"
	repository "backend-report/app/repositories/report"
	"context"
 "fmt"
	"gopkg.in/mgo.v2/bson"
	"io/ioutil"
	"log"
	"net/http"
)

type ReportServiceInterface interface {
	SaveReport(ctx context.Context, reportingSource string) error
}

// ReportService , implements ReportServiceInterface
// creates reports
type ReportService struct {
	reportingSource string
	repository      repository.Repository
}

func NewReporter(reportRepo repository.Repository) ReportServiceInterface {
	return &ReportService{repository: reportRepo}
}

func (r *ReportService) SaveReport(ctx context.Context, reportingSource string) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, reportingSource, nil)
 if err != nil { return err }
 resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}

defer resp.Body.Close()
 if resp.StatusCode != http.StatusOK { return fmt.Errorf("report source HTTP %d", resp.StatusCode) }
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return err
	}

	log.Println("Saving the new report to the database: " + string(body))

	report := models.Report{}
	err = bson.UnmarshalJSON(body, &report)
	if err != nil {
		return err
	}

	err = r.repository.Create(ctx, &report)
	if err != nil {
		return err
	}

	return nil
}
