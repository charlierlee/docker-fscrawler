import {ChangeDetectorRef, Component, OnInit} from '@angular/core';
import {SearchService} from '../shared/services/search.service';
import {environment} from '../../environments/environment';
import { FormControl, FormGroup, Validators } from '@angular/forms';
import { QueryModel } from '../models/QueryModel';
import { IndexChoice } from '../models/IndexChoice';

@Component({
    selector: 'app-home',
    templateUrl: './home.component.html',
    styleUrls: ['./home.component.scss']
})
export class HomeComponent implements OnInit {
    isConnected = false;
    status: string = "";
    totalHits: number = 0;
    searchTime: number = 0;
    currentPage: number = 0;
    searchResponse = '';
    PER_PAGE = environment.RESULTS_PER_PAGE;
    totalPages: number = 0;
    queryModel = new QueryModel();
    queryForm = new FormGroup({
        'unSanitizedQuery': new FormControl()
    });
    indices: IndexChoice[] = [
        {value: 'docker-compose', viewValue: 'owncloud'},
        {value: 'images', viewValue: 'images'}
    ];
    selectedIndex = 'images';
    public esData: any[] = [];

    /**
     * Elasticsearch misbehaves if users enter symbolic characters. User this method to strip out any such characters.
     * @param query - user search query.
     */
    static sanitized(query): string {
        return query.replace(/[&\/\\#,$%.':*?<>{}]/g, '');
    }

    constructor(private es: SearchService,
                private cd: ChangeDetectorRef) {
    }
    ngOnInit(): void {
        this.es.isAvailable().then(() => {
            this.status = 'OK';
            this.isConnected = true;
        }, error => {
            this.status = 'ERROR';
            this.isConnected = false;
            console.error('Server is down', error);
        }).then(() => {
            this.cd.detectChanges();
        });

        this.queryForm = new FormGroup({
            unSanitizedQuery: new FormControl(this.queryModel.unSanitizedQuery, [
            Validators.required,
            Validators.minLength(3)
          ]),
        });
      
    }
    get sanitizedQuery() 
    { 
        return HomeComponent.sanitized(this.queryModel.unSanitizedQuery); 
    }

    /**
     * Search function.
     * @param query - user input.
     * @param index - ES index to search.
     * @param page  - page.
     */
    search(page) {
        let index = this.selectedIndex;
        if (this.sanitizedQuery.length) {
            this.searchResponse = '';
            this.currentPage = page;
            // Search all indexes on ES
            if (index !== 'all') {
                this.es.getPaginatedDocuments(this.sanitizedQuery, page, index).then((body) => {
                    if (body.hits.total > 0) {
                        this.esData = body.hits.hits;
                        this.totalHits = body.hits.total;
                        this.searchTime = body.hits.time;
                        this.totalPages = Math.ceil(body.hits.total / this.PER_PAGE);
                    } else {
                        this.searchResponse = 'No matches found';
                    }
                }, (err) => {
                    this.searchResponse = 'Oops! Something went wrong... ERROR: ' + err.error;
                });
            } else {
                this.es.getPaginatedDocuments(this.sanitizedQuery, page).then((body) => {
                    if (body.hits.total > 0) {
                        this.esData = body.hits.hits;
                        this.totalHits = body.hits.total;
                        this.searchTime = body.took;
                        this.totalPages = Math.ceil(body.hits.total / this.PER_PAGE);
                    } else {
                        this.searchResponse = 'No matches found';
                    }
                }, (err) => {
                    this.searchResponse = 'Oops! Something went wrong... ERROR: ' + err.error;
                });
            }
        } else {
            this.searchResponse = 'Nothing found';
        }

    }

    nextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage += 1;
            if (this.sanitizedQuery.length) {
                this.search(this.currentPage);
            } else {
                this.esData = [];
                this.searchResponse = 'Nothing found';
            }
        }
    }

    previousPage() {
        if (this.currentPage - 1 >= 1) {
            this.currentPage -= 1;
            if (this.sanitizedQuery.length) {
                this.search(this.currentPage);
            } else {
                this.esData = [];
                this.searchResponse = 'Nothing found';
            }
        }
    }
}
