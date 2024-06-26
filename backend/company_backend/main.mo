import Utils "canister:utils_backend";
import User "canister:user_backend";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import TrieMap "mo:base/TrieMap";
import Result "mo:base/Result";
import Blob "mo:base/Blob";
// import Order "mo:base/Order";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Order "mo:base/Order";
import Vector "mo:vector/Class";

actor Database {

  type Company = {
    id : Text;
    name : Text;
    profile_description : Text;
    category : Text;
    location : [Text];
    image : Text;
    company_contact_ids : [Text];
    reviews_ids : [Text];
    user_principal : Text;
    timestamp : Time.Time;
  };

  type CompanyInputSchema = {
    name : Text;
    profile_description : Text;
    category : Text;
    location : [Text];
    user_principal : Text;
  };

  let companies = TrieMap.TrieMap<Text, Company>(Text.equal, Text.hash);

  public shared (msg) func createCompany(newCompany : CompanyInputSchema) : async Result.Result<Company, Text> {
    let _timestamp = Time.now();
    let uuid = await Utils.generateUUID();
    let image = "";
    let contactId = Principal.toText(msg.caller);

    let company : Company = {
      id = uuid;
      name = newCompany.name;
      profile_description = newCompany.profile_description;
      category = newCompany.category;
      location = newCompany.location;
      image = image;
      company_contact_ids = [contactId];
      reviews_ids = [];
      timestamp = _timestamp;
      user_principal = newCompany.user_principal;
    };

    companies.put(company.id, company);
    return #ok(company);
  };

  public shared query func getAllCompany(locationFilter : ?Text, search : ?Text, sort : ?Text) : async Result.Result<[Company], Text> {
    let result : [Company] = Iter.toArray(companies.vals());
    var companyData : [Company] = [];
    // sort data
    let sortParam = Option.get(sort, ""); // kalau null jadi ""
    if (sortParam == "name") {
      companyData := Array.sort(
        result,
        func(a : Company, b : Company) : Order.Order {
          Text.compare(a.name, b.name);
        },
      );
    } else if (sortParam == "date") {
      companyData := Array.sort(
        result,
        func(a : Company, b : Company) : Order.Order {
          Text.compare(a.id, b.id);
        },
      );
    };

    // filter
    let loc = Option.get(locationFilter, "");
    if (loc != "") {
      let filteredCompanies = Array.filter(
        companyData,
        func(company : Company) : Bool {
          let foundLocation = Array.find(
            company.location,
            func(l : Text) : Bool {
              l == loc;
            },
          );
          Option.isSome(foundLocation);
        },
      );
      companyData := filteredCompanies;
    };

    // search
    let searchParam = Option.get(search, "");
    if (searchParam != "") {
      companyData := Array.filter(
        companyData,
        func(company : Company) : Bool {
          Text.contains(company.name, #text searchParam);
        },
      );
    };
    return #ok(companyData);
  };

  public query func getAllCompanyID() : async Result.Result<[Text], Text> {
    var ids = Vector.Vector<Text>();

    for (c in companies.vals()) {
      ids.add(c.id);
    };

    return #ok(Vector.toArray(ids));
  };

  public query func getCompanyById(id : Text) : async Result.Result<Company, Text> {
    let result = companies.get(id);

    switch (result) {
      case null {
        return #err("Not Found!");
      };
      case (?c) {
        return #ok(c);
      };
    };
  };

  public shared (msg) func deleteCompanyById(id : Text) : async Result.Result<Text, Text> {
    if (Principal.isAnonymous(msg.caller)) {
      return #err("Not Authorized!");
    };

    let company = companies.get(id);

    // NANTI ATUR YANG BISA DELETE CUMAN ADMIN

    if (company == null) {
      return #err("Not Found!");
    } else {
      ignore companies.remove(id);
      return #ok("Company Deleted Successfully!");
    };
  };

  public shared (msg) func updateCompanyById(id : Text, updatedCompany : CompanyInputSchema) : async Result.Result<Company, Text> {
    if (Principal.isAnonymous(msg.caller)) {
      return #err("Not Authorized!");
    };

    // NANTI ATUR YANG BISA UPDATE CUMAN ADMIN

    switch (companies.get(id)) {
      case null {
        return #err("Not Found!");
      };
      case (?existingCompany) {
        let updatedTimestamp = Time.now();

        let updatedCompanyData : Company = {
          id = id;
          name = updatedCompany.name;
          profile_description = updatedCompany.profile_description;
          category = updatedCompany.category;
          location = updatedCompany.location;
          image = existingCompany.image;
          company_contact_ids = existingCompany.company_contact_ids;
          reviews_ids = existingCompany.reviews_ids;
          timestamp = updatedTimestamp;
          user_principal = updatedCompany.user_principal;
        };

        companies.put(id, updatedCompanyData);
        return #ok(updatedCompanyData);
      };
    };
  };

  public shared (msg) func addCompanyReview(id : Text, reviewid : Text) : async Result.Result<Company, Text> {
    if (Principal.isAnonymous(msg.caller)) {
      return #err("Not Authorized!");
    };

    switch (companies.get(id)) {
      case null {
        return #err("Not Found!");
      };
      case (?existingCompany) {
        let updatedReviewsIds = Array.append<Text>(existingCompany.reviews_ids, [reviewid]);

        let updatedCompanyData : Company = {
          id = id;
          name = existingCompany.name;
          profile_description = existingCompany.profile_description;
          category = existingCompany.category;
          location = existingCompany.location;
          image = existingCompany.image;
          company_contact_ids = existingCompany.company_contact_ids;
          reviews_ids = updatedReviewsIds;
          timestamp = existingCompany.timestamp;
          user_principal = existingCompany.user_principal;
        };

        companies.put(id, updatedCompanyData);
        return #ok(updatedCompanyData);
      };
    };
  };

  public shared (msg) func deleteCompanyReviewById(id : Text, reviewid : Text) : async Result.Result<Company, Text> {
    if (Principal.isAnonymous(msg.caller)) {
      return #err("Not Authorized!");
    };

    switch (companies.get(id)) {
      case null {
        return #err("Not Found!");
      };
      case (?existingCompany) {
        let updatedCompanyReviews = Array.filter<Text>(
          existingCompany.reviews_ids,
          func(review : Text) : Bool { review != reviewid },
        );

        let updatedCompanyData : Company = {
          id = id;
          name = existingCompany.name;
          profile_description = existingCompany.profile_description;
          category = existingCompany.category;
          location = existingCompany.location;
          image = existingCompany.image;
          company_contact_ids = existingCompany.company_contact_ids;
          reviews_ids = updatedCompanyReviews;
          timestamp = existingCompany.timestamp;
          user_principal = existingCompany.user_principal;
        };

        companies.put(id, updatedCompanyData);
        return #ok(updatedCompanyData);
      };
    };
  };

};
